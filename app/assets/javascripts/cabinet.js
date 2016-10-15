function SetCost() {
    var data1 = parseInt($("#tsserver_slots").val());
    var data2 = $('#SelectTime').val();
    data2 = parseInt(data2);
    var data = data1 * 3 * data2;
    $('.cost').html(data);
}

$('#SelectTime').bind('click', function(event){
    SetCost();
});

$("#tsserver_slots").bind("keyup focusout", function(event){
    var data = parseInt($("#tsserver_slots").val());
    if (data>512)
    {
        $('#tsserver_slots').val(512);
        data = 512;
        SetCost();
    }

    if (data>=10)
    {
        var selector = $("[data-slider]");
        selector.simpleSlider("setValue", data);
        SetCost();

    }

});

$("#tsserver_slots").bind("focusout", function(event){
    var data = parseInt($("#tsserver_slots").val());
    if (data<10)
    {
        $('#tsserver_slots').val(10);
        var selector = $("[data-slider]");
        selector.simpleSlider("setValue", 10);
        SetCost();

    }
});

$("[data-slider]").bind("slider:ready slider:changed", function (event, data) {
    $('#tsserver_slots').val(data.value.toFixed(0));
    SetCost();


});


