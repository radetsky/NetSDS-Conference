<?php
$db_engine="sqlite"; //can be mysql or sqlite mysql recommended for production

###########################SQLite Options####################################
$sqlite_location="/var/database/asterikast.db";
###########################Mysql Options#####################################
$mysql_hostname="localhost";
$mysql_username="asteriskuser";
$mysql_password="";
$mysql_db="conference";
###########################Recording Options#################################
$recordings_location="/var/recordings";
$recordings_username="apache";
###########################Manager Options###################################
$manager_host = "127.0.0.1";
$manager_username = "asterikast";
$manager_password = "asterikast";
###########################Speaking Options##################################
$use_module=0;
?>
