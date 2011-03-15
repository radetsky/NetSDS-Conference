var humanReadable = {
    'email_reminder' : 'Почтовое напоминание',
    'record' : 'Звукозапись',
    'leaved' : 'Участник вышел',
    'stopped' : 'Совещание остановлено',
    'voice_reminder' : 'Голосовое напоминание',
    'started' : 'Совещание начато',
    'joined' : 'Участник вошёл'
};

function select_logs() {
	var cnf = $('#cnfr_log').val();
	var from = $('#log_from').val();
	var to = $('#log_to').val();
	$.getJSON('/get_json_logs.pl', {"cnf": cnf, "from": from, "to": to}, function(data){
		$('#log_list').empty();
		$('#logsFancy').hide(0);
		var odd = false;
		if(data) {
		    if(data.status == "error") {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return false;
		    }
		    if(data.logs.length > 0) {
			$('#log_list').append('<thead><tr><th width="10%">Время</th><th width="10%">Событие</th><th width="20%">Расшифровка</th><th width="40%">Данные</th></tr></thead>');
		    }
		    for(var x=0; x<data.logs.length; x++) {
			if(odd) {
			    odd = false;
			    y = '<tr class="gray">';
			} else {
			    odd = true;
			    y = '<tr>';
			}
			// y = '<tr>';
			y += '<td>'+data.logs[x].time+'</td>';
			y += '<td>'+data.logs[x].type+'</td>';
			y += '<td>';
			if(humanReadable[data.logs[x].type]){
				y += humanReadable[data.logs[x].type];
			}
			y += '</td>';
			if(data.logs[x].type == 'record' && data.logs[x].field.length>0) {
				y += '<td><a href="/recorded/'+data.logs[x].field+'.wav">'+data.logs[x].field+'</a></td>';
			} else {
				y += '<td>'+data.logs[x].field+'</td>';
			}
			y += '</tr>';
			$('#log_list').append(y);
		    }
		    if(data.logs.length > 0) {
			$('#logsFancy').show(0);
		    }
		}
		// $("#log_list tr:nth-child(odd)").addClass("odd");
	});
}
