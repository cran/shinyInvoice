box::use(
  shiny[...],
  stats[runif]
)

box::use(
  .. / logic / exchange[...],
  .. / logic / save_files[...],
  .. / utils / constants[...],
  .. / utils / continue_sequence[...]
)

ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("currency_date"))
}

server <- function(id, rv_jsons, sublist, salary_currency, inputs, file_reac, temp_folder_session, bump_month_vars) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$currency_date <- renderUI({
      wellPanel(
        h4(strong("Invoice and Final Currency")),
        splitLayout(
          div(
            class = "flex-dates",
            actionButton(ns("increaseInvoiceNumber"), ""),
            actionButton(ns("decreaseInvoiceNumber"), "")
          ),
          tagList(
            div(
              class = "go-center",
              textInput(
                ns("invoice_number"), "Invoice Number",
                rv_jsons[[sublist]]$invoice_number
              )
            )
          )
        ),
        br(),
        div(
          class = "two_column_grid",
          textInput(
            ns("final_currency"),
            "",
            rv_jsons[[sublist]]$final_currency
          ),
          div(
            class = "go-center-vertical",
            div(
              id = "exchange_container", style = "display:inline-block", title = "Updates exchange values in other tabs",
              actionButton(
                ns("get_exchanges"),
                "Get exchange values"
              )
            )
          )
        ),
        splitLayout(
          div(
            class = "flex-dates",
            br(),
            actionButton(ns("increaseDates"), ""),
            span("1 Month"),
            actionButton(ns("decreaseDates"), "")
          ),
          tagList(
            dateInput(ns("exchangeDate"),
              div(
                class = "wrap",
                "Currency Exchange Date: "
              ),
              value = as.Date(rv_jsons[[sublist]]$exchangeDate)
            ),
            dateInput(ns("invoiceDate"), "Invoice Date: ", value = as.Date(rv_jsons[[sublist]]$invoiceDate))
          )
        ),
        downloadButton(ns("button_id"),
          class = "button",
          strong(
            "Save and Download", code("invoice_and_final_currency.json")
          ),
          style = "white-space: normal;
                   word-wrap: break-word;"
        )
      )
    })

    output$button_id <- downloadHandler(
      filename = function() {
        "invoice_and_final_currency.json"
      },
      content = function(file) {
        file_name <- "invoice_and_final_currency.json"
        folder <- gsub("file", "folder_", tempfile(tmpdir = file.path(temp_folder_session(), "tmp_dir")))
        dir.create(folder, recursive = TRUE)

        plain_json_save(
          input,
          plain_list = rv_jsons[[sublist]],
          folders = c(folder, file.path(temp_folder_session(), "json")),
          file_name
        )

        json_path <- file.path(folder, file_name)
        file.copy(json_path, file)
      },
      contentType = "json"
    )

    observeEvent(c(input$increaseDates, bump_month_vars$increaseEverything()), ignoreInit = TRUE, {
      if (input$increaseDates > 0 || bump_month_vars$increaseEverything() > 0) {
        cdate <- input$invoiceDate
        edate <- input$exchangeDate

        new_date_c <- date_bump_month(cdate)
        new_date_e <- date_bump_month(edate)

        updateDateInput(session, "invoiceDate", value = new_date_c)
        updateDateInput(session, "exchangeDate", value = new_date_e)
      }
    })

    observeEvent(c(input$increaseInvoiceNumber, bump_month_vars$increaseEverything()), ignoreInit = TRUE, {
      if (input$increaseInvoiceNumber > 0 || bump_month_vars$increaseEverything() > 0) {
        last <- get_last_symbol(input$invoice_number)
        vector <- continue_sequence(input$invoice_number, sep = last)
        updateTextInput(session, "invoice_number", value = vector[length(vector)])
      }
    })

    observeEvent(c(input$decreaseDates, bump_month_vars$decreaseEverything()), ignoreInit = TRUE, {
      if (input$decreaseDates > 0 || bump_month_vars$decreaseEverything() > 0) {
        cdate <- input$invoiceDate
        edate <- input$exchangeDate

        new_date_c <- date_bump_month(cdate, decrease = TRUE)
        new_date_e <- date_bump_month(edate, decrease = TRUE)

        updateDateInput(session, "invoiceDate", value = new_date_c)
        updateDateInput(session, "exchangeDate", value = new_date_e)
      }
    })

    observeEvent(c(input$decreaseInvoiceNumber, bump_month_vars$decreaseEverything()), ignoreInit = TRUE, {
      if (input$decreaseInvoiceNumber > 0 || bump_month_vars$decreaseEverything() > 0) {
        last <- get_last_symbol(input$invoice_number)
        vector <- continue_sequence(input$invoice_number, sep = last, factor = -1)
        updateTextInput(session, "invoice_number", value = vector[length(vector)])
      }
    })

    observeEvent(file_reac(), {
      updateTextInput(
        session,
        "final_currency",
        value = rv_jsons[[sublist]]$final_currency
      )
      updateDateInput(
        session,
        "exchangeDate",
        value = as.Date(rv_jsons[[sublist]]$exchangeDate)
      )
      updateDateInput(
        session,
        "invoiceDate",
        value = as.Date(rv_jsons[[sublist]]$invoiceDate)
      )
      updateTextInput(
        session,
        "invoice_number",
        value = rv_jsons[[sublist]]$invoice_number
      )
    })

    currency_date_rv <- reactiveValues()

    observeEvent(c(bump_month_vars$update_everything()), ignoreInit = TRUE, {
      year_month_vec <- get_current_month_year()
      year_int <- year_month_vec[1]
      month_int <- year_month_vec[2]

      putative_invoice_number <- paste0(c(year_int, month_int), collapse = "-")

      updateTextInput(session, "invoice_number", value = putative_invoice_number)

      new_invoice_date <- get_new_date(input$invoiceDate, year_int, month_int, mon_span)

      new_exchange_date <- get_new_date(input$exchangeDate, year_int, month_int, mon_span)

      updateDateInput(
        session,
        "exchangeDate",
        value = new_exchange_date
      )

      updateDateInput(
        session,
        "invoiceDate",
        value = new_invoice_date
      )

      start_month_date <- paste0(c(year_int, month_int, "1"), collapse = "-") |> as.Date()

      currency_date_rv$start_month_date <- start_month_date
    })

    observeEvent(input$get_exchanges, {
      showModal(modalDialog(
        title = "Getting all exchange rates",
        "An alert will pop-up if currency is not found!"
      ))
      currency_date_rv$exchange_salary <- 1
      if (toupper(input$final_currency) != toupper(salary_currency())) {
        exchange_value <- try_exchange_rates_direct_and_indirect(input$exchangeDate, input$final_currency, salary_currency())

        if (inherits(exchange_value, "numeric")) {
          exchange_salary <- signif(exchange_value, 5)
          currency_date_rv$exchange_salary <- exchange_salary
        } else {
          showNotification(paste0("the exchange for ", toupper(salary_currency()), " was not found"))
        }
      }

      inputs_list <- reactiveValuesToList(inputs)
      oneliner_ns <- "oneliner_ns"
      oneliners_currency_name_strings <- grep(paste0(oneliner_ns, ".*currency"), names(inputs_list), value = TRUE)
      grouped_currency_name_strings <- grep("grouped.*currency", names(inputs_list), value = TRUE)

      oneline_currencies_inputs <- inputs_list[which(names(inputs_list) %in% oneliners_currency_name_strings)]
      grouped_currency_inputs <- inputs_list[which(names(inputs_list) %in% grouped_currency_name_strings)]

      oneliners_currencies_list <- oneline_currencies_inputs[sapply(oneline_currencies_inputs, is.character)]
      grouped_currencies_list <- grouped_currency_inputs[sapply(grouped_currency_inputs, is.character)]

      oneliners_currency_exchange_value_list <- oneline_currencies_inputs[sapply(oneline_currencies_inputs, is.numeric)]

      oneliners_currencies_list_names <- names(oneliners_currency_exchange_value_list)
      oneliners_currencies_list_names_no_ns <- sub(paste0("^", oneliner_ns, "-"), "", oneliners_currencies_list_names)

      currency_date_rv$exchange_oneliners <- list()
      for (currency_idx in seq_along(oneliners_currencies_list)) {
        currency <- oneliners_currencies_list[currency_idx]
        currency_date_rv$exchange_oneliners[oneliners_currencies_list_names_no_ns[currency_idx]] <- 1

        if (toupper(input$final_currency) != toupper(currency)) {
          exchange_value <- try_exchange_rates_direct_and_indirect(input$exchangeDate, input$final_currency, currency)

          if (inherits(exchange_value, "numeric")) {
            exchange_oneliner <- signif(exchange_value, 5)
            currency_date_rv$exchange_oneliners[oneliners_currencies_list_names_no_ns[currency_idx]] <- exchange_oneliner
          } else {
            showNotification(paste0("the exchange for ", toupper(currency), " was not found"))
          }
        }
      }

      for (currency_idx in seq_along(grouped_currencies_list)) {
        currency <- grouped_currencies_list[currency_idx]
        currency_date_rv$exchange_grouped <- 1
        if (toupper(input$final_currency) != toupper(currency)) {
          exchange_value <- try_exchange_rates_direct_and_indirect(input$exchangeDate, input$final_currency, currency)


          if (inherits(exchange_value, "numeric")) {
            exchange_grouped <- signif(exchange_value, 5)
            currency_date_rv$exchange_grouped <- exchange_grouped
          } else {
            showNotification(paste0("the exchange for ", toupper(currency), " was not found"))
          }
        }
      }

      removeModal()
    })

    outputOptions(output, "currency_date", suspendWhenHidden = FALSE)

    return(list(
      exchange_salary = reactive({
        currency_date_rv$exchange_salary
      }),
      exchange_grouped = reactive({
        currency_date_rv$exchange_grouped
      }),
      exchange_oneliners = reactive({
        currency_date_rv$exchange_oneliners
      })
    ))
  })
}
