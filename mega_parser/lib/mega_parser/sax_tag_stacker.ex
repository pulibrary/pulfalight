defmodule MegaParser.SaxTagStacker do
  defmacro __using__(_params) do
    quote do
      @behaviour Saxy.Handler

      # A whitelist is added so that extra descriptive tags won't get indexed and the characters will get picked up.
      @whitelist [
        "abstract",
        "accessrestrict",
        "accruals",
        "acqinfo",
        "altformavail",
        "appraisal",
        "archdesc",
        "arrangement",
        "bibliography",
        "bioghist",
        "controlaccess",
        "corpname",
        "custodhist",
        "dao",
        "descgrp",
        "did",
        "ead",
        "eadheader",
        "eadid",
        "famname",
        "filedesc",
        "fileplan",
        "genreform",
        "geogname",
        "head",
        "langmaterial",
        "materialspec",
        "note",
        "odd",
        "originalsloc",
        "origination",
        "otherfindaid",
        "persname",
        "physdesc",
        "extent",
        "physloc",
        "phystech",
        "prefercite",
        "processinfo",
        "prodescrules",
        "relatedmaterial",
        "scopecontent",
        "separatedmaterial",
        "titleproper",
        "titlestmt",
        "unitdate",
        "unitdate/@normal",
        "unitid",
        "unittitle",
        "userestrict",
        "container",
        "c",
        "c01",
        "c02",
        "c03",
        "c04",
        "c05",
        "c06",
        "c07",
        "c08",
        "c09",
        "c10",
        "c11",
        "c12"
      ]

      def handle_event(:start_document, _prologue, state) do
        {:ok, initial_state()}
      end

      def handle_event(:end_document, _data, state), do: {:ok, state |> final_cleanup}

      def handle_event(:start_element, {name, _attributes}, state) when name not in @whitelist do
        {:ok, state}
      end

      def handle_event(:start_element, tag = {_name, _attributes}, state) do
        {:ok, state |> append_tag(tag) |> handle_tag_start(tag)}
      end

      def handle_event(:end_element, name, state) when name not in @whitelist do
        {:ok, state}
      end

      def handle_event(:end_element, tag, state) do
        {:ok, state |> drop_tag_stack |> handle_tag_end(tag)}
      end

      def handle_event(:characters, chars, state) do
        {:ok, state |> handle_text(chars)}
      end
    end
  end
end
