function edit_user(uid) {
	$("#edit_user").load('/user_form.pl', {id: uid}, function(data) {
		$("#op_rights").change(function(){
			$("#ad_op").slideToggle();
		});
		if(uid == 'new') {
		    $("#edit_user").dialog('option','title','Добавить пользователя:');
		} else {
		    $("#edit_user").dialog('option','title','Редактировать пользователя:');
		}
		$("#edit_user").dialog("open");
	});
}

function send_user() {
	var upass = $("#op_pass").val();
	var urepass = $("#op_repass").val();
	
	if(typeof(upass)!=='undefined') {
		if(upass.length > 0 && upass != urepass) {
			$("#error_text").empty();
			$("#error_text").append('Пароль и подтверждение пароля должны совпадать!');
			$("#error").dialog('open');
			return false;
		}
	}

	if($('#uname').val() == '') {
		$("#error_text").empty();
		$("#error_text").append('У пользователя должно быть какое-то имя');
		$("#error").dialog('open');
		return false;
	}

	var u_qry = 'save_user.pl?'+$("#modify_user").serialize();
	
	$.getJSON(u_qry, function (data) {
		if(data.status == 'error') {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return;
		}
		$("#edit_user").dialog("close");
		$("#users").load('/user_list.pl');

	});
}

function close_user_dialog() {
	$('#edit_user').dialog("close");
}

function add_phone_field() {
	var newid = $("#more_phones input").length + 1;
	var infield = '<input type="text" class="fit-column" name="phone'+newid+'" id="phone'+newid+'" value=""/><br/>';
	$("#more_phones").append(infield);
}

function remove_user(user_id) {
	if(confirm('Вы действительно хотите удалить пользователя?')) {
		$.getJSON('del_user.pl', { "user_id": user_id }, function (data) {
  	  if(data.status == 'error') {
    	  $("#error_text").empty();
      	$("#error_text").append(data.message);
	      $("#error").dialog('open');
  	    return;
	  	}
			$('#user'+user_id).remove();
		});
	}
}
