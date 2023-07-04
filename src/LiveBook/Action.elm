module LiveBook.Action exposing (importData, readData)

import Dict
import Lamdera
import LiveBook.DataSet
import LiveBook.Types exposing (CellValue(..))
import LiveBook.Update
import Types


readData : Int -> String -> String -> String -> Types.FrontendModel -> Types.FrontendModel
readData index fileName variable dataString model =
    let
        message =
            [ "Read from file `"
                ++ fileName
                ++ "`: "
                ++ (String.length dataString |> String.fromInt)
                ++ " characters, "
                ++ (dataString |> String.lines |> List.length |> String.fromInt)
                ++ " lines. \\"
            , "Data stored in variable `" ++ variable ++ "`"
            , ""
            , ""
            ]
                |> String.join "\n"
    in
    { model | kvDict = Dict.insert variable (quote dataString) model.kvDict, pressedKeys = [] }
        |> (\model_ -> LiveBook.Update.setCellValue model_ index (CVString message))


importData : Int -> String -> LiveBook.DataSet.DataSet -> Types.FrontendModel -> Types.FrontendModel
importData index variable dataset model =
    let
        message =
            [ "Imported: "
                ++ (String.length dataset.data |> String.fromInt)
                ++ " characters, "
                ++ (dataset.data |> String.lines |> List.length |> String.fromInt)
                ++ " lines"
            , ""
            , ""
            ]
                |> String.join "\n"
    in
    { model | kvDict = Dict.insert variable (quote (String.trim dataset.data)) model.kvDict, pressedKeys = [] }
        |> (\model_ -> LiveBook.Update.setCellValue model_ index (CVString message))


downloadDataSet : String -> Types.FrontendModel -> ( Types.FrontendModel, Cmd Types.ToBackend )
downloadDataSet identifier model =
    ( model, Lamdera.sendToBackend (Types.GetDataSetForDownload identifier) )


quote str =
    --"\" " ++ str ++ " \""
    str
