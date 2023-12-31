#' @name continue_sequence
#' @aliases continue_sequence, duplicate_last_list_element, date_bump_month
#' @title Functions continue_sequence, duplicate_last_list_element and date_bump_month
#' @description continue_sequence: suffix increase, i.e. from 1 to 2, from a to b
#' @description duplicate_last_list_element: copies last element from list and
#' bumps its name
#' @description date_bump_month: increases or decreases date by one month
#'
#' @param chr_vector character, vector
#' @param sep character, separating prefix from suffix
#' @param factor numeric, increase or decrease sequence
#'
#' @keywords sequential
#' @return vector
#' @rdname continue_sequence
#' @importFrom shiny isTruthy
#' @examples
#' continue_sequence(c("a_1", "a_2"))
#' duplicate_last_list_element(list(a_1 = "1", b_1 = "random"))
#' @export
continue_sequence <- function(chr_vector, sep = "_", factor = 1) {
  last_from_vector <- chr_vector[length(chr_vector)]

  if (is.numeric(suppressWarnings(as.numeric(last_from_vector))) &&
    isTruthy(suppressWarnings(as.numeric(last_from_vector))) && sep == "") {
    return(c(chr_vector, as.numeric(last_from_vector) + 1 * factor))
  }

  last_beg <- sub(paste0("(.*)", sep, "([[:alnum:]]+)?"), "\\1", grep(paste0(sep, "([[:alnum:]]*)$"),
    last_from_vector,
    value = TRUE
  ))

  last_end <- sub(paste0(".*", sep, "([[:alnum:]]+)"), "\\1", grep(paste0(sep, "([[:alnum:]]*)$"),
    last_from_vector,
    value = TRUE
  ))

  next_one <- 1
  numeric_end <- as.numeric(last_end)

  if (isTruthy(numeric_end)) {
    next_one <- (numeric_end + 1 * factor) |> abs()
  } else if (is.character(last_end) && length(last_end)) {
    split <- strsplit(last_end, "") |> unlist()
    last_char <- split[length(split)]
    last_char_beg <- sub(paste0(last_char, "$"), "", last_end)
    pos <- grep(last_char, letters)
    pos_A <- grep(last_char, LETTERS)
    if (length(pos)) {
      if (factor > 0) {
        next_one <- ifelse(last_char == "z", "aa", letters[pos + 1 * factor])
      } else {
        next_one <- ifelse(last_char == "a", "z", letters[pos + 1 * factor])
      }
      next_one <- paste0(last_char_beg, next_one)
    } else if (length(pos_A)) {
      if (factor > 0) {
        next_one <- ifelse(last_char == "Z", "AA", LETTERS[pos_A + 1 * factor])
      } else {
        next_one <- ifelse(last_char == "A", "Z", LETTERS[pos_A + 1 * factor])
      }
      next_one <- paste0(last_char_beg, next_one)
    } else {
      last_char <- sub(".*?([[:digit:]]+)$", "\\1", last_end)
      last_char_beg <- sub(paste0(last_char, "$"), "", last_end)
      next_one <- (as.numeric(last_char) + 1 * factor) |> abs()
      if (is.numeric(as.numeric(next_one)) && isTruthy(as.numeric(next_one))) {
        next_one <- paste0(last_char_beg, next_one)
      } else {
        next_one <- 1
      }
    }
  } else {
    warning("sep was not found in strings")
  }

  chr_vector <- c(chr_vector, paste0(last_beg, sep, next_one))
}

#' @rdname continue_sequence
#' @param list, list
#' @return data.frame
#' @export
duplicate_last_list_element <- function(list) {
  list_names <- names(list)
  list_with_appended_name <- continue_sequence(list_names)
  new_name <- list_with_appended_name[length(list_with_appended_name)]
  last_element <- list[length(list)]
  names(last_element) <- new_name
  last_element
}

#' @rdname continue_sequence
#' @param date, date
#' @param decrease, boolean
#' @importFrom lubridate year month day
#' @return date
#' @examples
#' date_bump_month(as.Date("2024-02-29"))
#' @export
date_bump_month <- function(date, decrease = FALSE) {
  year <- year(date)
  if (year %in% leap_years) {
    mon_span[3] <- 29
  }
  mon <- month(date)
  day <- day(date)

  modifier <- ifelse(day == mon_span[mon + 1], 1, 0)

  if (!decrease) {
    return(date + mon_span[mon + 1 + modifier])
  } else {
    subtract <- ifelse(day > mon_span[mon], day, mon_span[mon + modifier])
    date - subtract
  }
}
