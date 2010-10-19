			function edit_org(oid, oname) {
				if(oid == 'new') {
					$("#orglegend").text('Добавить организацию:');
					$("#orgbutton").attr("value", 'Создать');
//					$("#add_org").attr("title", 'Добавить имя организации');
				} else {
					$("#orglegend").text('Редактировать организацию:');
					$("#orgbutton").attr("value", 'Сохранить');
//					$("#add_org").attr("title", 'Редактировать имя организации');
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

			function edit_pos(pid, pname) {
				if(pid == 'new') {
					$("#poslegend").text('Добавить должность:');
					$("#posbutton").attr("value", 'Создать');
					$("#add_pos").attr("title", 'Добавить название должности');
				} else {
					$("#poslegend").text('Редактировать должность:');
					$("#posbutton").attr("value", 'Сохранить');
					$("#add_pos").attr("title", 'Редактировать название должности');
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

			function edit_user(uid) {
				$("#edit_user").load('/user_form.pl', {id: uid}, function(data) {
					$("#op_rights").change(function(){
						$("#ad_op").slideToggle();
					});
					$("#edit_user").dialog("open");
				});
			}

			function send_user() {
				var upass = $("#op_pass").val();
				var urepass = $("#op_repass").val();
				if(upass.length > 0 && upass != urepass) {
					$("#error_text").empty();
					$("#error_text").append('Пароль и подтверждение пароля должны совпадать!');
					$("#error").dialog('open');
					return;
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
				var infield = '<input type="text" name="phone'+newid+'" id="phone'+newid+'" value=""/><br/>';
				$("#more_phones").append(infield);
			}

