function edit_org(oid, oname) {
	if('new' == oid + '') {
		$("#orglegend").text('Добавить организацию:');
		$("#orgbutton").text('Добавить');
	} else {
		$("#orglegend").text('Редактировать организацию:');
		$("#orgbutton").text('Сохранить');
//		$("#add_org").dialog("option", "title", 'Редактировать имя организации');
	}
	$("#orgid").attr("value", oid);
	$("#orgname").attr("value", oname);
	$("#add_org").dialog("open");
}

function send_org() {
	var orgid = $("#orgid").val();
	var orgname = $("#orgname").val();
	$('#add_org').dialog("close");
	if ( orgname == "" ) {
		alert ( "Пустое имя организации" );
	} else {
		$("#orgs").load('/orgs.pl',{ name: orgname, id: orgid}); 
	}
}

function close_org_dialog() {
	$('#add_org').dialog("close");
}

function remove_org(org_id) {
	if(confirm('Вы действительно хотите удалить организацию?')) {
		$.getJSON('del_org.pl', { "org_id": org_id }, function (data) {
  	  if(data.status == 'error') {
    	  $("#error_text").empty();
      	$("#error_text").append(data.message);
	      $("#error").dialog('open');
  	    return;
	  	}
			$('#org'+org_id).remove();
		});
	}
}
