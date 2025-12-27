import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
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

pub type Machine {
  Machine(joltages: dict.Dict(Int, Int), buttons: dict.Dict(Int, List(Int)))
}

fn parse_p2(input) {
  input
  |> list.map(fn(lst) {
    let button_strs = list.drop(lst, 1) |> list.take(list.length(lst) - 2)
    let j_levels =
      list.last(lst)
      |> result.unwrap("")
      |> string.split(",")
      |> list.index_map(fn(s, idx) {
        let j = int.parse(s) |> result.unwrap(-1)
        #(idx, j)
      })
      |> dict.from_list
    let buttons =
      list.map(button_strs, fn(butt_str) {
        string.split(butt_str, ",")
        |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      })
      |> list.index_map(fn(el, idx) { #(idx, el) })
      |> dict.from_list

    Machine(j_levels, buttons)
  })
}

type State {
  State(buttons_pressed: List(Int), value: Int)
}

fn rec_try_buttons(
  queue: List(State),
  visited: set.Set(Int),
  target: Int,
  buttons: List(Int),
) -> Result(State, String) {
  case queue {
    [] -> Error("Target unreachable")
    [curr_state, ..rest] -> {
      case curr_state.value == target {
        True -> Ok(curr_state)
        False -> {
          let #(new_queue, new_visited) =
            list.fold(buttons, #(rest, visited), fn(acc, button) {
              let #(curr_queue, curr_visited) = acc
              let new_state =
                State(
                  value: int.bitwise_exclusive_or(curr_state.value, button),
                  buttons_pressed: [button, ..curr_state.buttons_pressed],
                )
              case set.contains(visited, new_state.value) {
                True -> acc
                False -> {
                  #(
                    list.append(curr_queue, [new_state]),
                    set.insert(curr_visited, new_state.value),
                  )
                }
              }
            })
          rec_try_buttons(new_queue, new_visited, target, buttons)
        }
      }
    }
  }
}

fn try_buttons_p1(wanted: Int, buttons: List(Int)) -> State {
  let initial_state = State([], 0)
  let visited = set.new() |> set.insert(0)
  let queue = [initial_state]
  let final_state = rec_try_buttons(queue, visited, wanted, buttons)
  case final_state {
    Ok(state) -> state
    Error(s) -> panic as s
  }
}

fn find_odd_joltages(machine: Machine) {
  let size = dict.size(machine.joltages)
  list.range(0, size - 1)
  |> list.map(fn(key) {
    let assert Ok(joltage) = dict.get(machine.joltages, key)
    case is_even(joltage) {
      True -> 0
      False -> 1
    }
  })
}

fn is_even(joltage: Int) -> Bool {
  joltage % 2 == 0
}

fn is_odd(val: Int) -> Bool {
  !is_even(val)
}

pub fn day10p1(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p1

  let res =
    list.map(inp, fn(part) {
      let #(wanted, buttons) = part
      let final_state = try_buttons_p1(wanted, buttons)
      list.length(final_state.buttons_pressed)
    })
    |> int.sum
  io.println("Day 10 part 1 : " <> int.to_string(res))
  res
}

pub fn solve_mach(machine: Machine, button_combos: List(List(Int))) {
  rec_find_solution(machine, dict.new(), button_combos)
}

fn find_btn_combos(button_count: Int) -> List(List(Int)) {
  // No of combos is 2^button count
  let combo_count = int.bitwise_shift_left(1, button_count)
  // Generate all combinations of button presses 0 or 1 time
  let combos =
    list.range(0, combo_count - 1)
    |> list.map(fn(el) {
      int.to_base2(el)
      |> string.pad_start(button_count, "0")
      |> string.to_graphemes
      |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
    })
  combos
}

fn rec_find_solution(
  machine: Machine,
  memo: dict.Dict(List(Int), Int),
  button_combos: List(List(Int)),
  // Precalculated button combos
) -> #(Int, dict.Dict(List(Int), Int)) {
  let key = jolt_dict_to_key(machine.joltages)
  case dict.get(memo, key) {
    Ok(val) -> #(val, memo)
    Error(_) -> {
      let #(res_val, updated_memo) = case is_all_zeros(machine) {
        True -> #(0, memo)
        False -> {
          // Make a list of 1:s for each odd joltage or
          // 0 for each even joltage level
          let odds = find_odd_joltages(machine)

          case find_joltage_deltas_and_counts(button_combos, machine, odds) {
            [] -> #(999_999, memo)
            deltas -> {
              list.fold(deltas, #(999_999, memo), fn(acc, delta_item) {
                let #(current_best_count, curr_memo) = acc

                let #(delta, count, _combo) = delta_item

                let new_jolts = subtract_deltas(machine.joltages, delta)
                let next_machine = Machine(new_jolts, machine.buttons)
                case has_negatives(next_machine) {
                  True -> acc
                  False -> {
                    let half_machine = calc_half_joltages(next_machine)
                    let #(inner, next_memo) =
                      rec_find_solution(half_machine, curr_memo, button_combos)
                    let total_count =
                      count
                      + {
                        case inner {
                          icnt if icnt >= 0 -> icnt * 2
                          _ -> 999_999
                        }
                      }
                    let new_best = int.min(current_best_count, total_count)
                    #(new_best, next_memo)
                  }
                }
              })
            }
          }
        }
      }
      #(
        res_val,
        dict.insert(updated_memo, jolt_dict_to_key(machine.joltages), res_val),
      )
    }
  }
}

fn jolt_dict_to_key(dict: dict.Dict(Int, Int)) -> List(Int) {
  dict.to_list(dict)
  |> list.map(fn(el) { el.1 })
}

/// Takes the current joltages and a dictionary of deltas,
/// returning a new dictionary with the deltas subtracted.
fn subtract_deltas(
  joltages: dict.Dict(Int, Int),
  delta: dict.Dict(Int, Int),
) -> dict.Dict(Int, Int) {
  dict.fold(over: delta, from: joltages, with: fn(acc, key, dval) {
    case dict.get(acc, key) {
      // If the key exists, subtract and update the accumulator
      Ok(current_val) -> dict.insert(acc, key, current_val - dval)

      // If the key doesn't exist, return the accumulator unchanged
      Error(_) -> acc
    }
  })
}

fn calc_half_joltages(machine: Machine) {
  let new_jolts = dict.map_values(machine.joltages, fn(_key, val) { val / 2 })
  Machine(new_jolts, machine.buttons)
}

fn has_negatives(machine: Machine) -> Bool {
  list.any(dict.values(machine.joltages), fn(el) { el < 0 })
}

fn is_all_zeros(machine: Machine) -> Bool {
  list.all(dict.values(machine.joltages), fn(el) { el == 0 })
}

fn find_joltage_deltas_and_counts(
  combos: List(List(Int)),
  machine: Machine,
  odds: List(Int),
) -> List(#(dict.Dict(Int, Int), Int, List(Int))) {
  list.map(combos, fn(combo) {
    let deltas =
      list.index_fold(combo, dict.new(), fn(acc, el, idx) {
        case el == 1 {
          True -> {
            // Press the button with number idx
            let buttons_to_press =
              dict.get(machine.buttons, idx) |> result.unwrap([])
            list.fold(buttons_to_press, acc, fn(acc, button) {
              dict.upsert(acc, button, fn(opt_jolt) {
                case opt_jolt {
                  option.Some(val) -> val + 1
                  option.None -> 1
                }
              })
            })
          }
          False -> acc
        }
      })
    let btn_press_cnt = int.sum(combo)
    #(deltas, btn_press_cnt, combo)
  })
  |> list.filter(fn(deltas) {
    list.index_fold(odds, True, fn(acc, should_be_odd, idx) {
      let delta = dict.get(deltas.0, idx) |> result.unwrap(0)
      case should_be_odd == 1 {
        True -> acc && is_odd(delta)
        False -> acc && is_even(delta)
      }
    })
  })
}

pub fn day10p2(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p2

  // Get the max and min button count
  let sizes =
    inp
    |> list.fold(from: #(0, 100), with: fn(acc, machine) {
      let #(max_size, min_size) = acc
      let size = dict.size(machine.buttons)
      #(int.max(max_size, size), int.min(min_size, size))
    })

  let pre_calculated_button_combos = calculate_button_combos(sizes)

  let res =
    list.map(inp, fn(mach) {
      let button_combos =
        dict.get(pre_calculated_button_combos, dict.size(mach.buttons))
        |> result.unwrap([])
      solve_mach(mach, button_combos).0
    })
    |> int.sum
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}

fn calculate_button_combos(
  sizes: #(Int, Int),
) -> dict.Dict(Int, List(List(Int))) {
  let #(min_size, max_size) = sizes
  list.range(min_size, max_size)
  |> list.map(fn(button_count) {
    #(button_count, find_btn_combos(button_count))
  })
  |> dict.from_list
}
