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
				var uid = $("#uid").val();
				var uname = $("#fio").val();
				var oid = $("#user_org").val();
				var dept = $("#user_dept").val();
				var pid = $("#user_pos").val();
				var uemail = $("#user_email").val();
				var uop = $("input[name='op_rights']:checked").length;
				var ulogin = $("#op_login").val();
				var upass = $("#op_pass").val();
				var urepass = $("#op_repass").val();

				if(upass.length > 0 && upass != urepass) {
					alert('Пароли не совпадают');
					return;
				}

				var uadmin = $("input[name='is_admin']:checked").length;
				
				var phones = $("#phone0").val();
				var phone_cnt = $("#more_phones input").length;
				for (i=1;i<=phone_cnt;i++) {
					var field = '#phone'+i;
					var nextp = $(field).val();
					if(nextp.length > 0) {
						phones += '+'+nextp;
					}
				}
				$('#edit_user').dialog("close");

				
				$("#users").load('/user_list.pl',{ id: uid, phones: phones, name: uname, orgid: oid, dept: dept, posid: pid, email: uemail, oper: uop, login: ulogin, passwd: upass, admin: uadmin});
			}

			function close_user_dialog() {
				$('#edit_user').dialog("close");
			}

			function add_phone_field() {
				var newid = $("#more_phones input").length + 1;
				var infield = '<input type="text" name="phone'+newid+'" id="phone'+newid+'" value=""/><br/>';
				$("#more_phones").append(infield);
			}

