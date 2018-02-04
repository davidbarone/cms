(function($) {
  $.fn.grid = function(o) {
    var cfg = {
      key: '',              // the data field containing primary / unique key
      size: 10,             // default page size
      sort: '',             // sort column
      multiSelect: false,   // enable row multiselect

      // data
      url: null,            // url used to get data

      columns: [],
      buttons: [],

      cssRowSelected: 'gridRowSelected',      // grid style

      // events
      getData: function(page, size) {},   // raised when control needs a page of data
      rowClick: function(row, selected) { },  // raised when row clicked by user
      rowDblClick: function(row, selected) { },
      renderRow: function(row) { },           // allows overriding of default row rendering.
      renderHeader: function(headers) { }     // allows overriding of header rendering.
    };

    // extend any optional parameters passed in with the defaults
    $.extend(true, cfg, o);

    // for each item in the wrapped set,
    // create a grid, and return a 'modified' object
    // with enhanced grid stuff in it.
    return this.each(function() {
      var grid = this;
      $(grid).extend(grid, {
        
        // data properties
        selectedIDs: [],    // rows selected
        selectedRow: {},
        
        // parts of the grid
        _table: null,       // main table
        _divAbove: null,   // header div
        _divBelow: null,   // footer div

        // sorting * paging
        _sort: cfg.sort || cfg.key,
        _direction: 'ASC',
        _page: 1,

        // clears grid
        clear: function() {
          grid.selectedIDs = [];
          $(grid).find('#' + grid.id + '_data').empty();
        },

        // creates new grid
        init: function() {
          grid.buildGrid();
          grid.clear();
          grid.getData(1, cfg.size);
        },

        getData_cb: function(json) {
          // buttons
          var divButtons = $('#' + grid.id + "_buttons");
          divButtons.empty()
          for (var i = 0; i < cfg.buttons.length; i++) {
	    $('<input type="button" value="' + cfg.buttons[i].value + '"/>')
            .data("index",i)
            .click(function() {
              if (cfg.buttons[$(this).data("index")].click) {
                cfg.buttons[$(this).data("index")].click(grid.selectedRow);
              }
            })
            .appendTo(divButtons);
          }

          // pager
          var divPager = $('#' + grid.id + "_pager").empty();

          // first
          var setFirst = $('<input type="button" value="<<" id="' + grid.id + '_first" />')
          .click(function() { grid.getData(1, json.size); })
          .appendTo(divPager);

          // previous
          var setFirst = $('<input type="button" value="<" id="' + grid.id + '_prev" />')
          .click(function() { grid.getData((json.page > 1 ? json.page - 1 : 1), json.size); })
          .appendTo(divPager);

          // set page
          var setPage = $('<input type="text" value="' + json.page + '" style="width:50px;" id="' + grid.id + '_page" />')
          .blur(function() {grid.getData($(this).val(), json.size);})
          .appendTo(divPager);

          // next
          var setFirst = $('<input type="button" value=">" id="' + grid.id + '_next" />')
          .click(function() { grid.getData((json.page < Math.ceil(json.rows / json.size) ? json.page + 1 : Math.ceil(json.rows / json.size)), json.size); })
          .appendTo(divPager);

          // last
          var setFirst = $('<input type="button" value=">>" id="' + grid.id + '_last" />')
          .click(function() { grid.getData(Math.ceil(json.rows / json.size), json.size); })
          .appendTo(divPager);

          // get key
          if (cfg.key == '' && json.data.length > 0) {
            // assume the first property is the key
            for (var i in json.data[0]) {
              cfg.key = i;
              break;
            }
          }

          // add column headers
          grid.loadColumnHeaders(json);

          // load rows
          for (var r = 0; r < json.size; r++) {
            var row = json.data[r];
            
            // allow user to override rendering of data
            cfg.renderRow(row);
            
            var tableRow = $('<tr/>')
            .attr('rowid', row[cfg.key])
            .data('row', row)
            .toggle(
              function() {
                if (cfg.multiSelect == true) {
                  $(this).addClass(cfg.cssRowSelected)
                  .attr('selected', true);
                  var rowid = $(this).attr('rowid');
                  grid.selectedIDs.push(rowid);
                }
              },
              function() {
                if (cfg.multiSelect == true) {
                  $(this).removeClass(cfg.cssRowSelected)
                  .attr('selected', false);
                  var rowid = $(this).attr('rowid');
                  grid.selectedIDs.splice($.inArray(rowid, grid.selectedIDs), 1);
                }
              }
            )
            .dblclick(function() {
              if(cfg.rowDblClick) {
                // the data-row attribute comes from the $.data() method
                cfg.rowDblClick($(this).data('row'));
              }
            })
            .click(function() {
              if (cfg.multiSelect == false) {
                grid.selectedIDs = [];
                $(grid._table).find('tr')
                .removeClass(cfg.cssRowSelected)
                .attr('selected', false);
                $(this).addClass(cfg.cssRowSelected)
                .attr('selected', true);
                var rowid = $(this).attr('rowid');
                grid.selectedIDs.push(rowid);
                grid.selectedRow = $(this).data('row');
              }

              //var row = grid._data[$(this).attr('rowid')];
              if(cfg.rowClick) {
                // the data-row attribute comes from the $.data() method
                cfg.rowClick($(this).data('row'), $(this).attr('selected'));
              }
            }) // converts json to object.
            .appendTo(grid._table);

            for (var i=0; i<cfg.columns.length; i++) {
              var col = cfg.columns[i];
              $('<td/>')
              .html(row[col])
              .attr('title', row[col])
              .appendTo(tableRow);
            }
          }
        },

        getData: function(page, size) {
          grid._page = page;

          // remove existing page
          $(grid._divBody).find('div').remove();

          // data either comes from server (url)
          // or javascript (getData)
          if (cfg.url != null) {
            $.ajax({
              type: 'GET',
              url: cfg.url,
              dataType: 'json',
              data: {
                page: page,
                size: size,
                sort: 'ABC',
                direction: 'ASC'
              },
              success: function(json) {
                grid.getData_cb(json);
              }
            });
          } else if (cfg.getData != null) {
            json = cfg.getData(page, size, grid._sort, grid._direction);
            grid.getData_cb(json)
          } else {
            alert('Either url or getData MUST be specified');
          }
        },

        loadColumnHeaders: function(json) {
          $(grid._table).find('tr').remove();
          if (json.data.length > 0 && (cfg.columns==null || cfg.columns.length===0)) {
            cfg.columns = [];
            for (var propertyName in json.data[0]) {
              cfg.columns.push(propertyName);
            }
          }

          cfg.renderHeader(cfg.columns);

          var tableRow = $('<tr />')
          .appendTo(grid._table);

          for (var i in cfg.columns) {
            var header = $('<th />')
            .html(cfg.columns[i])

            // prevent text being selected (improves UX)
            .attr('unselectable', 'on')
            .css('MozUserSelect', 'none')
            .bind('selectstart', function() { return false; })
            .attr('sort', i)
            .hover(
              function() { $(this).css('cursor', 'pointer') },
              function() { $(this).css('cursor', 'default') }
            )
            .click(function() {
              grid._sort = $(this).attr('sort');
              grid._direction = grid._direction == "ASC" ? "DESC" : "ASC";
              grid.clear();
              grid.getData(grid._page,cfg.size);
            })
            .appendTo(tableRow);
          }
        },

        // Builds the initial grid
        buildGrid: function() {

          // header
          grid._divAbove = $('<div id="' + grid.id + '_header"/>')
          .appendTo(grid);

          // table
          grid._table = $('<table id="' + grid.id + '"/>')
          .appendTo(grid);

          // footer
          grid._divBelow = $('<div id="' + grid.id + '_footer"/>')
          .appendTo(grid);

          // header + footer decorations
          $('<div id="' + grid.id + '_pager"></div>')
          .appendTo(grid._divBelow);

          $('<div id="' + grid.id + '_buttons" style="display:inline;">Buttons</div>')
          .appendTo(grid._divAbove);

        }
      });
      this.init();
    });
  };
})(jQuery);