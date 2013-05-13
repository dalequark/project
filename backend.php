<?php

/* Variables set based on request fields for various connection types */

$action = $_GET["action"]; /* The reason the device is contacting the server. May be to connect for the first time, request data, or send data of a certain type */
$uuid = $_GET["uuid"]; /* The unique identifier for the device */
$task; /* Task name, used for response */
$phone; /* The phone number of the device */
$interval; /* The frequency for the cron job */
$sensor;
$db; /* The database */

/* We respond with json strings */
header('Content-type: application/json');

/* Connect to the database */
$db = new mysqli('localhost', 'cstedman', 'HCIhc!hci', 'cstedman_hci');

/* If database connection error... */
if ($db->connect_error) {
    exit('Connect Error (' . $db->connect_errno . ') '
            . $db->connect_error);
}

/* Log connection to logfile for debugging purposes */
$log = $action . $uuid . "\n";
$logfile = "logfile";
file_put_contents($logfile, $log, FILE_APPEND);

/* If we successfully received data, parse */
if ($action && $uuid) {

	/* If the device is connecting for the first time */
	if ($action == "connect") {
		$task = $_GET["task"]; /* Task name */
		$phone = $_GET["phone"]; /* Device phone number */
		$interval = $_GET["interval"]; /* Frequency with which server will send updates to user */
		$sensor = $_GET["sensor"];
		echo('{"status": "success", "message": "received action '.$action.' for uuid '.$uuid.' and task '.$task.'"}');

		$dbCheck = "SELECT uuid FROM connections WHERE uuid = '$uuid'";
		if ($result = $db->query($dbCheck)) {
			while ($row = mysqli_fetch_assoc($result)) {
				if ($row['uuid'] == $uuid) {
					mysqli_free_result($result);
					exit();
				}
			}
			mysqli_free_result($result);
		}

		$insertData = "INSERT INTO connections
		(uuid, phone, task, `interval`, increment)
		VALUES
		('$uuid', '$phone', '$task', $interval * 3600, 0, $sensor, 0)";

		$result = $db->query($insertData);

		if(!$result) {
			echo('{"status": "error", "message": "Fatal error posting data to database"}');
		}
	}

	else if ($action == "info") {

		$dbCheck = "SELECT * FROM connections WHERE uuid = '$uuid'";
		if ($result = $db->query($dbCheck)) {
			while ($row = mysqli_fetch_assoc($result)) {
				if ($row['uuid'] == $uuid) {
					echo('{"status": "success", "action": "'.$action.'", "uuid": "'.$uuid.'", "task": "'.$row["task"].'", "interval": "'.$row["interval"].'", "sensor": "'.$row["sensor"].'", "counter": "'.$row["counter"].'"}');
					
					/* Log connection to logfile for debugging purposes */
					$log = '{"status": "success", "action": "'.$action.'", "uuid": "'.$uuid.'", "task": "'.$row["task"].'", "interval": "'.$row["interval"].'", "sensor": "'.$row["sensor"].'"}';
					$logfile = "logfile";
					file_put_contents($logfile, $log, FILE_APPEND);

					mysqli_free_result($result);
					exit();
				}
			}
			mysqli_free_result($result);
			echo('{"status": "error", "message": "uuid not found in database"}');

			/* Log connection to logfile for debugging purposes */
			$log = '{"status": "error", "message": "uuid not found in database"}';
			$logfile = "logfile";
			file_put_contents($logfile, $log, FILE_APPEND);
		}
		else {
			echo('{"status": "error", "message": "database query failed"}');

			/* Log connection to logfile for debugging purposes */
			$log = '{"status": "error", "message": "database query failed"}';
			$logfile = "logfile";
			file_put_contents($logfile, $log, FILE_APPEND);
		}
	}

	else if ($action == "gyro" || $action == "accel" || $action == "magneto") {
		echo('{"status": "success", "message": "received action '.$action.' for uuid '.$uuid.'"}');

		$timestamp = date("Y-m-d H:i:s");

		$insertData = "INSERT INTO events
		(uuid, time)
		VALUES
		('$uuid', '$timestamp')";

		$result = $db->query($insertData);

		if (!$result) {
			echo('{"status": "error", "message": "Fatal error posting data to database"}');
		}
	}

	else if ($action == "disconnect") {

		$dbQuery = "DELETE FROM events WHERE uuid = '$uuid'";
		$result = $db->query($dbQuery);

		if (!$result) {
			echo('{"status": "error", "message": "Error disconnecting sensor from database"}');
		}

		$dbQuery = "DELETE FROM connections WHERE uuid = '$uuid'";
		$result = $db->query($dbQuery);

		if (!$result) {
			echo('{"status": "error", "message": "Error disconnecting sensor from database"}');
		}

		echo('{"status": "success", "message": "Device successfully disconnected"}');
	}

	else echo('{"status": "error", "message": "invalid action"}');

} else {
	echo('{"status": "error", "message": "missing action or uuid"}');
}

$db->close();

?>