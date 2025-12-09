import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

fn get_input(path: String) {
  utils.get_input_lines(path)
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split(",")
    |> list.map(fn(s) {
      let assert Ok(n) = int.parse(s)
      n
    })
  })
}

pub fn day9p1(path: String) -> Int {
  let input = get_input(path)
  let pairs = list.combination_pairs(input)
  let res =
    list.fold(pairs, 0, fn(acc, pl) {
      case pl {
        #([r1, c1], [r2, c2]) -> {
          let area =
            { int.absolute_value(r2 - r1) + 1 }
            * { int.absolute_value(c2 - c1) + 1 }
          int.max(area, acc)
        }

        _ -> panic as "Err in coord pair"
      }
    })
  io.println("Day 9 part 1 : " <> int.to_string(res))
  res
}

fn get_rows(lst) {
  lst
  |> list.map(fn(p) {
    case p {
      [_, sec, ..] -> sec
      _ -> panic
    }
  })
  |> list.sort(int.compare)
  |> list.unique
}

fn get_columns(lst) {
  lst
  |> list.map(fn(p) {
    case p {
      [first, ..] -> first
      _ -> panic
    }
  })
  |> list.sort(int.compare)
  |> list.unique
}

fn get_hor_lines(rows, points) {
  rows
  |> list.map(fn(row) {
    let points =
      list.filter(points, fn(pair) {
        case pair {
          [_c, r] -> r == row
          _ -> panic as "Not a pair"
        }
      })
  })
}

fn get_vert_lines(cols, points) {
  cols
  |> list.map(fn(col) {
    let points =
      list.filter(points, fn(pair) {
        case pair {
          [c, _r] -> c == col
          _ -> panic as "Not a pair"
        }
      })
  })
}

fn is_inside(point, hor_lines, vert_lines) {
  let c = case point {
    [c, _r] -> c
    _ -> panic as "Wrong point"
  }
  let act_hor_lines =
    list.filter(hor_lines, fn(line) {
      case line {
        [[c1, _r1], [c2, _r2]] -> c <= int.max(c1, c2) && c >= int.min(c1, c2)
        _ -> panic as "Not a pair"
      }
    })
}

pub fn day9p2(path: String) -> Int {
  let points = get_input(path)
  let columns = points |> get_columns
  let rows = points |> get_rows
  let hor_lines = get_hor_lines(rows, points) |> echo
  let vert_lines = get_vert_lines(columns, points) |> echo
  let res = 0
  io.println("Day 9 part 2 : " <> int.to_string(res))
  res
}
