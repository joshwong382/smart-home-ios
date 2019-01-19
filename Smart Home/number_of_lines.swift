import SwiftyJSON 
 let nol_str = """

{"header" : {
  "cloc_url"           : "github.com/AlDanial/cloc",
  "cloc_version"       : "1.80",
  "elapsed_seconds"    : 0.0526328086853027,
  "n_files"            : 21,
  "n_lines"            : 4655,
  "files_per_second"   : 398.990677574539,
  "lines_per_second"   : 88442.9335290227},
"Swift" :{
  "nFiles": 21,
  "blank": 1015,
  "comment": 622,
  "code": 3018},
"SUM": {
  "blank": 1015,
  "comment": 622,
  "code": 3018,
  "nFiles": 21} }
"""
let nol_json = JSON(parseJSON: nol_str)
let number_of_lines = nol_json["Swift"]["code"].intValue
