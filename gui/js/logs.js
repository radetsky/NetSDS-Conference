function select_logs() {
	var cnf = $('#cnfr_log').val();
	var from = $('#log_from').val();
	var to = $('#log_to').val();
	$.getJSON('/get_json_logs.pl', {"cnf": cnf, "from": from, "to": to}, function(data){
		$('#log_list').empty();
		if(data.status == "error") {
			$("#error_text").empty();
			$("#error_text").append(data.message);
			$("#error").dialog('open');
			return false;
		}
		for(var x=0; x<data.logs.length; x++) {
			y = '<tr>';
			y += '<td>'+data.logs[x].time+'</td>';
			y += '<td>'+data.logs[x].type+'</td>';
			if(data.logs[x].type == 'record' && data.logs[x].field.length>0) {
				y += '<td><a href="/recorded/'+data.logs[x].field+'.wav">'+data.logs[x].field+'</a></td>';
			} else {
				y += '<td>'+data.logs[x].field+'</td>';
			}
			y += '</tr>';
			$('#log_list').append(y);
		}
		$("#log_list tr:nth-child(odd)").addClass("odd");
	});
}
