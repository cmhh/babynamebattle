$(document).on("click", ".restore", function(e) {
  e.preventDefault();
  $el = $(this);
  var name = $el.data("name");
  Shiny.onInputChange("restore", {
    name: name
  });
});
