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


