<?php
$flagPause = $_GET['flagPause'];
$date_utc = new \DateTime("now", new \DateTimeZone("UTC"));
if ($flagPause != "SET") {
    echo shell_exec("/usr/bin/sudo /opt/openziti/scripts/zetdisplay.sh");
}
echo "<span id=\"ZETDATE-BROWSER\" class=\"CENTERDATE FULLWIDTH OPACITY-D\">LAST REQUESTED : " . $date_utc->format(\DateTime::RFC850) . "</span>";
?>