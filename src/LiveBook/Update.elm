module LiveBook.Update exposing
    ( clearCell
    , clearNotebookValues
    , deleteCell_
    , editCell
    , evalCell
    , evalCell_
    , executeCell_
    , makeNewCell
    , updateCellText
    )

import File.Select
import Lamdera
import List.Extra
import LiveBook.Eval
import Types exposing (Cell, CellState(..), FrontendModel, FrontendMsg(..))


clearNotebookValues : Types.Book -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
clearNotebookValues book model =
    let
        newBook =
            { book | cells = List.map (\cell -> { cell | value = Nothing }) book.cells }
    in
    ( { model | currentBook = newBook }, Lamdera.sendToBackend (Types.SaveNotebook newBook) )


executeCell_ : Int -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
executeCell_ index model =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            ( model, Cmd.none )

        Just cell_ ->
            let
                updatedCell =
                    { cell_ | cellState = CSView }

                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells
                        |> List.map (\cell -> { cell | index = cell.index })
                        |> List.map (\cell -> { cell | cellState = CSView })

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ (updatedCell :: suffix), dirty = True }

                commandWords =
                    cell_.text
                        |> String.join "\n"
                        |> String.trim
                        |> String.replace "# " ""
                        |> String.words

                cmd =
                    case List.head commandWords of
                        Nothing ->
                            Cmd.none

                        Just "read" ->
                            case List.Extra.getAt 1 commandWords of
                                Nothing ->
                                    Cmd.none

                                Just variable ->
                                    File.Select.file [ "text/csv" ] (StringDataSelected index variable)

                        _ ->
                            Cmd.none
            in
            ( { model | currentBook = newBook }, cmd )


makeNewCell : FrontendModel -> Int -> ( FrontendModel, Cmd FrontendMsg )
makeNewCell model index =
    let
        newCell =
            { index = index + 1
            , text = [ "# New cell (" ++ String.fromInt (index + 2) ++ ") ", "-- code --" ]
            , value = Nothing
            , cellState = CSEdit
            }

        prefix =
            List.filter (\cell -> cell.index <= index) model.currentBook.cells
                |> List.map (\cell -> { cell | cellState = CSView })

        suffix =
            List.filter (\cell -> cell.index > index) model.currentBook.cells
                |> List.map (\cell -> { cell | index = cell.index + 1 })
                |> List.map (\cell -> { cell | cellState = CSView })

        oldBook =
            model.currentBook

        newBook =
            { oldBook | cells = prefix ++ (newCell :: suffix), dirty = True }
    in
    ( { model
        | cellContent = ""
        , currentBook = newBook
        , currentCellIndex = index + 1
      }
    , Cmd.none
    )


updateCellText : FrontendModel -> Int -> String -> FrontendModel
updateCellText model index str =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            model

        Just cell_ ->
            let
                updatedCell =
                    { cell_ | text = str |> String.split "\n" }

                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ (updatedCell :: suffix), dirty = True }
            in
            { model | cellContent = str, currentBook = newBook }


deleteCell_ : Int -> FrontendModel -> FrontendModel
deleteCell_ index model =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            model

        Just cell_ ->
            let
                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView, index = cell.index - 1 })

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ suffix, dirty = True }
            in
            { model | currentCellIndex = cell_.index, cellContent = cell_.text |> String.join "\n", currentBook = newBook }


editCell : FrontendModel -> Int -> ( FrontendModel, Cmd FrontendMsg )
editCell model index =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            ( model, Cmd.none )

        Just cell_ ->
            let
                updatedCell =
                    { cell_ | cellState = CSEdit }

                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ (updatedCell :: suffix), dirty = True }
            in
            ( { model | currentCellIndex = cell_.index, cellContent = cell_.text |> String.join "\n", currentBook = newBook }, Cmd.none )


clearCell : FrontendModel -> Int -> ( FrontendModel, Cmd FrontendMsg )
clearCell model index =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            ( model, Cmd.none )

        Just cell_ ->
            let
                updatedCell =
                    { cell_ | text = [ "" ], cellState = CSView }

                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ (updatedCell :: suffix), dirty = True }
            in
            ( { model | cellContent = "", currentBook = newBook }, Cmd.none )


evalCell_ : Int -> FrontendModel -> FrontendModel
evalCell_ index model =
    case List.Extra.getAt index model.currentBook.cells of
        Nothing ->
            model

        Just cell_ ->
            let
                updatedCell =
                    LiveBook.Eval.evaluateWithCumulativeBindings model.currentBook.cells cell_

                prefix =
                    List.filter (\cell -> cell.index < index) model.currentBook.cells
                        |> List.map (\cell -> { cell | cellState = CSView })

                suffix =
                    List.filter (\cell -> cell.index > index) model.currentBook.cells

                oldBook =
                    model.currentBook

                newBook =
                    { oldBook | cells = prefix ++ (updatedCell :: suffix), dirty = True }

                --|> List.map LiveBook.Cell.evaluate
            in
            { model | currentBook = newBook }


evalCell : FrontendModel -> Int -> ( FrontendModel, Cmd FrontendMsg )
evalCell model index =
    ( evalCell_ index model, Cmd.none )
