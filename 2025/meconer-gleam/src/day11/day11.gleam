import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

fn get_input(path: String) {
  let parts =
    utils.get_input_lines(path)
    |> list.map(fn(s) {
      let parts =
        string.trim(s)
        |> string.split(":")
      let assert [in, outs] = parts
      let outputs =
        string.trim(outs)
        |> string.split(" ")
      #(in, outputs)
    })
  dict.from_list(parts)
}

fn count_paths(conns, start, target) {
  case start == target {
    True -> 1
    False -> {
      let assert Ok(outputs) = dict.get(conns, start)
      list.fold(outputs, 0, fn(acc, dev) {
        acc + count_paths(conns, dev, target)
      })
    }
  }
}

fn count_paths_p2(
  conns: dict.Dict(String, List(String)),
  curr_dev: String,
  target: String,
  path: List(String),
  memo: dict.Dict(String, Int),
) -> #(Int, dict.Dict(String, Int)) {
  case curr_dev == target {
    True -> {
      echo path
      let valid_path = list.contains(path, "fft") && list.contains(path, "dac")
      echo valid_path
      case valid_path {
        True -> {
          echo path
          #(1, memo)
        }
        False -> #(0, memo)
      }
    }
    False -> {
      case dict.has_key(memo, curr_dev) {
        True -> {
          // We counted from here already. 
          #(dict.get(memo, curr_dev) |> result.unwrap(-1), memo)
        }
        False -> {
          let assert Ok(outputs) = dict.get(conns, curr_dev)
          list.fold(outputs, #(0, memo), fn(acc, dev) {
            let #(cnt, n_memo) =
              count_paths_p2(conns, dev, target, [dev, ..path], acc.1)
            let new_memo =
              dict.merge(acc.1, n_memo)
              |> dict.insert(dev, cnt)
            #(acc.0 + cnt, new_memo)
          })
        }
      }
    }
  }
}

pub fn day11p1(path: String) -> Int {
  let conns = get_input(path)

  let res = count_paths(conns, "you", "out")
  io.println("Day 11 part 1 : " <> int.to_string(res))
  res
}

pub fn day11p2(path: String) -> Int {
  let conns = get_input(path)

  let memo: dict.Dict(String, Int) = dict.new()
  let #(res, _memo) = count_paths_p2(conns, "svr", "out", [], memo)
  io.println("Day 11 part 2 : " <> int.to_string(res))
  res
}
