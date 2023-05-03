<?php
$date_utc = new \DateTime("now", new \DateTimeZone("UTC"));
echo "<span id=\"ZETDATE-BROWSER\" class=\"CENTERDATE FULLWIDTH\">BROWSER DATE: " . $date_utc->format(\DateTime::RFC850) . "</span><br>";
echo shell_exec("/usr/bin/sudo /opt/NetFoundry/scripts/zetdisplay.sh");
?>