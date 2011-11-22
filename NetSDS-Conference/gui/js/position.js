function edit_pos(pid, pname) {
	if(pid == 'new') {
		$("#poslegend").text('Добавить должность:');
		$("#posbutton").text('Добавить');
	} else {
		$("#poslegend").text('Редактировать должность:');
		$("#posbutton").text('Сохранить');
	}
	$("#posid").attr("value", pid);
	$("#posname").attr("value", pname);
	$("#add_pos").dialog("open");
}

function send_pos() {
	var posid = $("#posid").val();
	var posname = $("#posname").val();
	$('#add_pos').dialog("close");
	if ( posname == "" ) {
		alert ( "Пустое имя организации" );
	} else {
		$("#posns").load('/posns.pl',{ name: posname, id: posid}); 
	}
}

function close_pos_dialog() {
	$('#add_pos').dialog("close");
}

function del_pos(pos_id) {
	if(confirm('Вы действительно хотите удалить должность?')) {
		$.getJSON('del_pos.pl', { "pos_id": pos_id }, function (data) {
			if(data.status == 'error') {
				$("#error_text").empty();
				$("#error_text").append(data.message);
				$("#error").dialog('open');
				return;
			}
			$('#pos'+pos_id).remove();
		});
	}
}
