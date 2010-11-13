function edit_org(oid, oname) {
	if(oid == 'new') {
		$("#orglegend").text('Добавить организацию:');
		$("#orgbutton").attr("value", 'Создать');
//		$("#add_org").attr("title", 'Добавить имя организации');
	} else {
		$("#orglegend").text('Редактировать организацию:');
		$("#orgbutton").attr("value", 'Сохранить');
//		$("#add_org").attr("title", 'Редактировать имя организации');
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
