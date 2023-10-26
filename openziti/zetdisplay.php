<?php
$flagPause = $_GET['flagPause'];
$date_utc = new \DateTime("now", new \DateTimeZone("UTC"));
echo "<span id=\"ZETDATE-BROWSER\" class=\"CENTERDATE FULLWIDTH\">BROWSER DATE: " . $date_utc->format(\DateTime::RFC850) . "</span>";
if ($flagPause != "SET") {
    echo "<br>";
    echo shell_exec("/usr/bin/sudo /opt/NetFoundry/scripts/zetdisplay.sh");
}
?>