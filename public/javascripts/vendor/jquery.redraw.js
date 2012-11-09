// force dom element redraws to work around chrome bugs
;$.fn.redraw = function() {
  return $(this).each(function() {
    var n = document.createTextNode(' ');
    $(this).append(n);
    setTimeout(function() { n.parentNode.removeChild(n); }, 0);
  });
};
