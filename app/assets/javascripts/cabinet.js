$(document).on('turbolinks:load', function() {
    function SetCost() {
        var data2 = parseInt($('#tsserver_time_payment').val());
        var data1 = parseInt($("#tsserver_slots").val());
        var data = data1 * 3 * data2;
        $('span.cost').text(data);
    }

    $('#tsserver_time_payment').bind('click', function(event){
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
});


