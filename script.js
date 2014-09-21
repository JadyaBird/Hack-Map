function initialize() {
        var mapOptions = {
        center: { lat: 48.8128006, lng: -82.7721806},
        zoom: 5
    };
    var map = new google.maps.Map(document.getElementById('map-canvas'),
        mapOptions);
}
google.maps.event.addDomListener(window, 'load', initialize);

var map = new GMap2(document.getElementById("map"));
map.setCenter(new GLatLng(37.4419, -122.1419), 13);
GEvent.addListener(map, "click", function() {
  alert("You clicked the map.");
});