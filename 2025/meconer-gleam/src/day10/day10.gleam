import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import utils

fn get_input(path: String) {
  utils.get_input_lines(path)
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split(" ")
    |> list.map(fn(s) { string.slice(s, 1, string.length(s) - 2) })
  })
}

fn parse_p1(input) {
  input
  |> list.map(fn(lst) { list.take(lst, list.length(lst) - 1) })
  |> list.map(fn(lst) {
    case lst {
      [want_str, ..button_strs] -> {
        let wanted =
          string.to_graphemes(want_str)
          |> list.index_fold(0, fn(acc, gr, idx) {
            case gr {
              "." -> acc
              "#" -> acc + int.bitwise_shift_left(1, idx)
              _ -> panic as "Only # or . allowed"
            }
          })
        let buttons =
          list.map(button_strs, fn(butt_str) {
            string.split(butt_str, ",")
            |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
            |> list.fold(0, fn(acc, i) { acc + int.bitwise_shift_left(1, i) })
          })

        #(wanted, buttons)
      }
      _ -> panic as "Err in input"
    }
  })
}

type State {
  State(button_pressed: List(Int), value: Int)
}

fn try_buttons(wanted: Int, buttons: List(Int)) -> Int {
  let indicator = 0
  let visited_state = set.new() |> set.insert(State([], 0))
  //Initial value
  let queue = []
  0
}

pub fn day10p1(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p1
    |> echo

  list.map(inp, fn(part) {
    let #(wanted, buttons) = part
    let count = try_buttons(wanted, buttons)
  })
  let res = 0
  io.println("Day 10 part 1 : " <> int.to_string(res))
  res
}

pub fn day10p2(path: String) -> Int {
  let points = get_input(path)
  let res = 0
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}
