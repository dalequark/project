<?php
include 'SendMessage.php';

$db;
$uuid;
$interval;
$increment;
$counter;
$secondsBetweenCron = 3600;

/* Connect to the database */
$db = new mysqli('localhost', 'cstedman', 'HCIhc!hci', 'cstedman_hci');

/* If database connection error... */
if ($db->connect_error) {
    exit('Connect Error (' . $db->connect_errno . ') '
            . $db->connect_error);
}

$dbQuery = "SELECT * from connections";
if ($result = $db->query($dbQuery)) {
	while ($row = mysqli_fetch_assoc($result)) {
		$uuid        = $row['uuid'];
		$interval    = $row['interval'];
		$increment   = $row['increment'];
		$counter     = $row['counter'];
		$timestamp   = $row['lastcheck'];
		$phonenumber = $row['phone'];
		$task        = $row['task'];

		$increment = ($increment + $secondsBetweenCron) % $interval;

		if($increment == 0) {

			/*phonenumber as a string, message as a string*/

			$dbQuery = "SELECT * from events WHERE uuid = '".$uuid."'";

			if ($result2 = $db->query($dbQuery)) {
				$parity = FALSE;

				while ($row2 = mysqli_fetch_assoc($result2)) {
					$lastCron = $row2['time'];
					if (strtotime($lastCron) > strtotime($timestamp)) {
					
						/* Log connection to logfile for debugging purposes */
						$log = "good news!\n";
						$logfile = "crontest";
						file_put_contents($logfile, $log, FILE_APPEND);
				
						$dbQuery = "UPDATE connections SET counter = '".++$counter."' WHERE uuid = '".$uuid."'";
						$db->query($dbQuery);

						$parity = TRUE;
					}
				}

				if ($parity == FALSE) {

					/* Log connection to logfile for debugging purposes */
					$log = $task."\n";
					$logfile = "crontest";
					file_put_contents($logfile, $log, FILE_APPEND);

					/* SENDMESSAGE *//*
					$message = "Hello. This is an update concerning your scheduled task, ".$task.". You have not reinforced your habit recently.";
					SendMessage($phonenumber, $message);*/
				}
				mysqli_free_result($result2);
			}

			/* SET THE NEW DATETIME */
			$timestamp = date("Y-m-d H:i:s");
			$dbQuery = "UPDATE connections SET lastcheck = '".$timestamp."' WHERE uuid = '".$uuid."'";
			$db->query($dbQuery);
			
			/* Log connection to logfile for debugging purposes */
			$log = $timestamp."\n";
			$logfile = "crontest";
			file_put_contents($logfile, $log, FILE_APPEND);
		}

		$dbQuery = "UPDATE connections SET increment = ".$increment." WHERE uuid = '".$uuid."'";
		$db->query($dbQuery);
	}
	mysqli_free_result($result);
} 

?>