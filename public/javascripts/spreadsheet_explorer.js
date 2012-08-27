function annotation_source(id, type, name, url) {
  this.id = id;
  this.type = type;
  this.name = name;
  this.url = url;
  this.annotations = [];
}

function annotation(id, type, sheet_number, cell_range, content, date_created) {
  this.id = id;
  this.type = type;
  this.sheetNumber = sheet_number;
  this.cellRange = cell_range;
  this.content = content;
  this.dateCreated = date_created;

  var cell_coords = explodeCellRange(cell_range);
  this.startCol = cell_coords[0];
  this.startRow = cell_coords[1];
  this.endCol = cell_coords[2];
  this.endRow = cell_coords[3];
}

var $j = jQuery.noConflict(); //To prevent conflicts with prototype

$j(window)
      .resize(function(e) {
        adjust_container_dimensions();
});

$j(document).ready(function ($) {

  //Auto scrolling
  var xInc = "+=0";
  var yInc = "+=0";
  var slowScrollBoundary = 100; //Distance from the edge of the spreadsheet in pixels at which automatic scrolling starts when dragging out a selection
  var fastScrollBoundary = 50; //As above, but faster scrolling
  var scrolling = false;

  //Cell selection
  var isMouseDown = false,
      startRow,
      startCol,
      endRow,
      endCol;


  //To disable text-selection
  //http://stackoverflow.com/questions/2700000/how-to-disable-text-selection-using-jquery
  $.fn.disableSelect = function() {
    $(this).attr('unselectable', 'on')
        .css('-moz-user-select', 'none')
        .each(function() {
          this.onselectstart = function() { return false; };
        });
  };

  //Clickable worksheet tabs
  $("a.sheet_tab")
      .click(function () {
        activateSheet(null, $(this));
      })
      ;

  //Cell selection
  $("table.sheet td.cell")
      .mousedown(function () {
        if(!isMouseDown) {
          //Update the cell info box to contain either the value of the cell or the formula
          // also make hovering over the info box display all the text.
          if($(this).attr("title"))
          {
            $('#cell_info').val($(this).attr("title"));
            $('#cell_info').attr("title", $(this).attr("title"));
          }
          else
          {
            $('#cell_info').val($(this).html());
            $('#cell_info').attr("title", $(this).html());
          }
          isMouseDown = true;
          startRow = parseInt($(this).attr("row"));
          startCol = parseInt($(this).attr("col"));
        }

        select_cells(startCol, startRow, startCol, startRow);

        return false; // prevent text selection
      })
      .mouseover(function (e) {
        if (isMouseDown) {

          endRow = parseInt($(this).attr("row"));
          endCol = parseInt($(this).attr("col"));

          select_cells(startCol, startRow, endCol, endRow);
        }
      })
  ;

  //Auto scrolling when selection box is dragged to the edge of the view
  $("div.sheet")
      .mousemove(function (e) {
        if(isMouseDown)
        {
          var sheet = $("div.active_sheet");
          if(e.pageY >= (sheet.position().top + sheet.outerHeight()) - slowScrollBoundary)
            if(e.pageY >= (sheet.position().top + sheet.outerHeight()) - fastScrollBoundary)
              yInc =  "+=50px";
            else
              yInc =  "+=10px";
          else if (e.pageY <= (sheet.position().top + slowScrollBoundary))
            if (e.pageY <= (sheet.position().top + fastScrollBoundary))
              yInc = "-=50px";
            else
              yInc = "-=10px";
          else
            yInc = "+=0";

          if(e.pageX >= (sheet.position().left + sheet.outerWidth()) - slowScrollBoundary)
            if(e.pageX >= (sheet.position().left + sheet.outerWidth()) - fastScrollBoundary)
              xInc =  "+=50px";
            else
              xInc =  "+=10px";
          else if (e.pageX <= (sheet.position().left + slowScrollBoundary))
            if (e.pageX <= (sheet.position().left + fastScrollBoundary))
              xInc = "-=50px";
            else
              xInc = "-=10px";
          else
            xInc = "+=0";

          if(xInc == "+=0" && yInc == "+=0")
          {
            scrolling = false;
          }
          else if (!scrolling)
          {
            sheet.stop();
            scrolling = true;
            scroll(sheet);
          }
        }
      })
  ;

  //Scroll headings when sheet is scrolled
  $("div.sheet")
      .scroll(function (e) {
        $(this).parent().find("div.row_headings").scrollTop(($(this)).scrollTop());
        $(this).parent().parent().find("div.col_headings").scrollLeft(($(this)).scrollLeft());
      })
  ;

  //http://stackoverflow.com/questions/1511529/how-to-scroll-div-continuously-on-mousedown-event
  function scroll(object) {
    if(!scrolling)
      object.stop();
    else
    {
      object.animate({scrollTop : yInc, scrollLeft : xInc}, 100, function(){
        if (scrolling)
          scroll(object);
      });
    }
  };

  $(document)
      .mouseup(function () {
        if (isMouseDown)
        {
          isMouseDown = false;
          if(scrolling)
          {
            scrolling = false;
            $('div.active_sheet').stop();
          }
          //Hide annotations
          $('#annotation_container').hide();
          $('div.annotation').hide();
        }
      })
  ;

  //Select cells that are typed in
  $('input#selection_data')
      .keyup(function(e) {
        if(e.keyCode == 13) {
          select_range($(this).val());
        }
      })
  ;

  //Resizable column/row headings
  //also makes them clickable to select all cells in that row/column
  $( "div.col_heading" )
      .resizable({
        minWidth: 20,
        handles: 'e',
        stop: function (){
          $("table.active_sheet col:eq("+($(this).index()-1)+")").width($(this).width());
          if ($j("div.spreadsheet_container").width()>max_container_width()) {
            adjust_container_dimensions();
          }
        }
      })
      .mousedown(function(){
        var col = $(this).index();
        var last_row = $(this).parent().parent().parent().find("div.row_heading").size();
        select_cells(col,1,col,last_row);
      })
  ;
  $( "div.row_heading" )
      .resizable({
        minHeight: 15,
        handles: 's',
        stop: function (){
          var height = $(this).height();
          $("table.active_sheet tr:eq("+$(this).index()+")").height(height).css('line-height', height-2 + "px");
        }
      })
      .mousedown(function(){
        var row = $(this).index() + 1;
        var last_col = $(this).parent().parent().parent().find("div.col_heading").size();
        select_cells(1,row,last_col,row);
      })
  ;

  adjust_container_dimensions();
});

function max_container_width() {
    var max_width = $j(".corner_heading").width();
    $j(".col_heading:visible").each(function() {
       max_width += $(this).offsetWidth;
    });
    return max_width;
}

function adjust_container_dimensions() {
        var max_width = max_container_width();
        var spreadsheet_container_width = $j("div.spreadsheet_container").width();
        if (spreadsheet_container_width>=max_width) {
            $j(".spreadsheet_container").width(max_width);
            spreadsheet_container_width=max_width;
        }
        else {
            $j(".spreadsheet_container").width("95%");
            spreadsheet_container_width = $j("div.spreadsheet_container").width();
        }
        var sheet_container_width = spreadsheet_container_width + 14;
        var sheet_width = spreadsheet_container_width - 39;
        $j(".sheet").width(sheet_width);
        $j(".sheet_container").width(sheet_container_width);

//    var spreadsheet_container_height = $j("div.spreadsheet_container").height();
//    var sheet_height = spreadsheet_container_height - 20;
//    $j(".sheet").height(sheet_height);
//    $j(".sheet_container").height(spreadsheet_container_height);
}

//Convert a numeric column index to an alphabetic one
function num2alpha(col) {
  var result = "";
  col = col-1; //To make it 0 indexed.

  while (col >= 0)
  {
    result = String.fromCharCode((col % 26) + 65) + result;
    col = Math.floor(col/26) - 1;
  }
  return result;
}

//Convert an alphabetic column index to a numeric one
function alpha2num(col) {
  var result = 0;
  for(var i = col.length-1; i >= 0; i--){
    result += Math.pow(26,col.length - (i + 1)) * (col.charCodeAt(i) - 64);
  }
  return result;
}

//Turns an excel-style cell range into an array of coordinates
function explodeCellRange(range) {
  //Split into component parts (top-left cell, bottom-right cell of a rectangle range)
  var array = range.split(":",2);

  //Get a numeric value for the row and column of each component
  var startCol = alpha2num(array[0].replace(/[0-9]+/,""));
  var startRow = parseInt(array[0].replace(/[A-Z]+/,""));
  var endCol;
  var endRow;

  //If only a single cell specified...
  if(array[1] == undefined) {
    endCol = startCol;
    endRow = startRow;
  }
  else {
    endCol = alpha2num(array[1].replace(/[0-9]+/,""));
    endRow = parseInt(array[1].replace(/[A-Z]+/,""));
  }
  return [startCol,startRow,endCol,endRow];
}


//Process annotations
// Links them to their respective sheet/cell/cellranges
// Is called after every AJAX call to rebind the set of annotations that may have
// changed, and to re-enhance DOM elements that have been reloaded
function bindAnnotations(annotation_sources) {
  var annotationIndexTable = $j("div#annotation_overview table");
  for(var s = 0; s < annotation_sources.size(); s++)
  {
    var source = annotation_sources[s];

    //Add a new section in the annotation index for the source
    var stub_heading = $j("<tr></tr>").addClass("source_header").append($j("<td></td>").attr({colspan : 3})
        .append($j("<a>Annotations from " + source.name + "</a>").attr({href : source.url})))
        .appendTo(annotationIndexTable);

    for(var a = 0; a < source.annotations.size(); a++)
    {
      var ann = source.annotations[a];

      //Add a new "stub" in the index
      annotationIndexTable.append(createAnnotationStub(ann));

      //bind annotations to respective table cells
      if (ann.type!="plot_data") {
        bindAnnotation(ann);
      }
    }
  }
  //Text displayed in annotation index if no annotations present
  if(annotation_sources < 1)
  {
    annotationIndexTable.append($j("<tr></tr>").append($j("<td colspan=\"3\">No annotations found</td>")));
  }
  //Make the annotations draggable
  $j('#annotation_container').draggable({handle: '#annotation_drag', zIndex: 100000000000000});
}

//Small annotation summary that jumps to said annotation when clicked
function createAnnotationStub(ann)
{
    var type_class;
    var content;
    if (ann.type=="plot_data") {
        type_class="plot_data_type";
        content = "Graph data";
    }
    else {
        type_class="text_annotation_type";
        content = ann.content.substring(0,40);
    }
    var stub = $j("<tr></tr>").addClass("annotation_stub")
      .append($j("<td>&nbsp;</td>").addClass(type_class))
      .append($j("<td>Sheet"+(ann.sheetNumber+1)+"."+ann.cellRange+"</td>"))
      .append($j("<td>"+content+"</td>"))
      .append($j("<td>"+ann.dateCreated+"</td>"))
      .click( function (){
        jumpToAnnotation(ann.id, ann.sheetNumber, ann.cellRange);
      });

  return stub;
}

function bindAnnotation(ann) {
  $j("table.sheet:eq("+ann.sheetNumber+") tr").slice(ann.startRow-1,ann.endRow).each(function() {
            
    $j(this).children("td.cell").slice(ann.startCol-1,ann.endCol).addClass("annotated_cell")
          .click(function () {show_annotation(ann.id,
              $j(this).position().left + $j(this).outerWidth(),
              $j(this).position().top);}
          );
  });
}



function toggle_annotation_form(annotation_id) {
  var elem = 'div#annotation_' + annotation_id

  $j(elem + ' div.annotation_text').toggle();
  $j(elem + ' div.annotation_edit_text').toggle();
  $j(elem + ' #annotation_controls').toggle();
};



//To display the annotations
function show_annotation(id,x,y) {
  var annotation_container = $j("#annotation_container");
  var annotation = $j("#annotation_" + id);
  var plot_element_id = "annotation_plot_data_"+id;
  annotation_container.css('left',x+20);
  annotation_container.css('top',y-20);
  annotation_container.show();
  annotation.show();
  if ($j(plot_element_id)) {
    plot_cells(plot_element_id,'500','300');
  }

}


function jumpToAnnotation(id, sheet, range) {
  //Go to the right sheet
  activateSheet(sheet);

  //Select the cell range
  select_range(range);

  //Show annotation in middle of sheet
  var cells = $j('.selected_cell');
  show_annotation(id,
      cells.position().left + cells.outerWidth(),
      cells.position().top);
}

function select_range(range) {
  var coords = explodeCellRange(range);
  var startCol = coords[0],
      startRow = coords[1],
      endCol = coords[2],
      endRow = coords[3];

  if(startRow && startCol && endRow && endCol)
    select_cells(startCol, startRow, endCol, endRow);

  //Scroll to selected cells
  var row = $j("table.active_sheet tr").slice(startRow-1,endRow).first();
  var cell = row.children("td.cell").slice(startCol-1,endCol).first();

  $j('div.active_sheet').scrollTop(row.position().top + $j('div.active_sheet').scrollTop() - 500);
  $j('div.active_sheet').scrollLeft(cell.position().left + $j('div.active_sheet').scrollLeft() - 500);
}

function deselect_cells() {
  //Deselect any cells and headings
  $j(".selected_cell").removeClass("selected_cell");
  $j(".selected_heading").removeClass("selected_heading");
  //Clear selection box
  $j('#selection_data').val("");
  $j('#cell_info').val("");
  //Hide selection-dependent buttons
  $j('.requires_selection').hide();
}


//Select cells in a specified area
function select_cells(startCol, startRow, endCol, endRow) {
  var minRow = startRow;
  var minCol = startCol;
  var maxRow = endRow;
  var maxCol = endCol;

  //To ensure minRow/minCol is always less than maxRow/maxCol
  // no matter which direction the box is dragged
  if(endRow <= startRow) {
    minRow = endRow;
    maxRow = startRow;
  }
  if(endCol <= startCol) {
    minCol = endCol;
    maxCol = startCol;
  }

  //Deselect any cells and headings
  $j(".selected_cell").removeClass("selected_cell");
  $j(".selected_heading").removeClass("selected_heading");

  //"Select" dragged cells
  $j("table.active_sheet tr").slice(minRow-1,maxRow).each(function() {
    $j(this).children("td.cell:not(.selected_cell)").slice(minCol-1,maxCol).addClass("selected_cell");
  });

  //"Select" dragged cells' column headings
  $j("div.active_sheet").parent().parent().find("div.col_headings div.col_heading").slice(minCol-1,maxCol).addClass("selected_heading");

  //"Select" dragged cells' row headings
  $j("div.active_sheet").parent().find("div.row_headings div.row_heading").slice(minRow-1,maxRow).addClass("selected_heading");

  //Update the selection display e.g A3:B2
  var selection = "";
  selection += (num2alpha(minCol).toString() + minRow.toString());

  if(maxRow != minRow || maxCol != minCol)
    selection += (":" + num2alpha(maxCol).toString() + maxRow.toString());

  $j('#selection_data').val(selection);

  //Update cell coverage in annotation form
  $j('input.annotation_cell_coverage_class').attr("value",selection);

  //Show selection-dependent controls
  $j('.requires_selection').show();
}

function activateSheet(sheet, sheetTab) {
  if(sheetTab == null)
    sheetTab = $j("a.sheet_tab:eq(" + sheet +")");

  var sheetIndex = sheetTab.attr("index")

  //Clean up
  //Hide annotations
  $j('div.annotation').hide();
  $j('#annotation_container').hide();

  //Deselect previous tab
  $j('a.selected_tab').removeClass('selected_tab');

  //Disable old table + sheet
  $j('.active_sheet').removeClass('active_sheet');

  //Hide sheets
  $j('div.sheet_container').hide();

  //Select the tab
  sheetTab.addClass('selected_tab');

  //Show the sheet
  $j("div.sheet_container#spreadsheet_" + sheetIndex).show();

  var activeSheet = $j("div.sheet#spreadsheet_" + sheetIndex);

  //Show the div + set sheet active
  activeSheet.addClass('active_sheet');

  //Reset scrollbars
  activeSheet.scrollTop(0).scrollLeft(0);

  //Set table active
  activeSheet.children("table.sheet").addClass('active_sheet');

  deselect_cells();

  //Record current sheet in annotation form
  $j('input#annotation_sheet_id').attr("value",sheetIndex);

  //Reset variables
  isMouseDown = false,
      startRow = 0,
      startCol = 0,
      endRow = 0,
      endCol = 0;

  adjust_container_dimensions();
  return false;
}

function copy_cells()
{

  var cells = $j('td.selected_cell');
  var columns = $j('.col_heading.selected_heading').size();
  var text = "";

  for(var i = 0; i < cells.size(); i += columns)
  {
    for(var j = 0; j < columns; j += 1)
    {
      text += (cells.eq(i + j).html() + "\t");
    }
    text += "\n";
  }

  $j("textarea#export_data").val(text);
  $j("div.spreadsheet_popup").hide();
  $j("div#export_form").show();
}