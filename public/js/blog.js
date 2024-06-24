$(document).ready(function(){
    $("time.timeago").timeago();

    $('.updateButton').click(function() {
        $(this).siblings('.updateForm').toggle();
    });
});