<pre>
<?php
$date_utc = new \DateTime("now", new \DateTimeZone("UTC"));
echo "<div id=\"BRDATE\" class=\"CENTERDATE\">BROWSER DATE: " . $date_utc->format(\DateTime::RFC850) . "</div>";
echo shell_exec("/usr/bin/sudo /opt/NetFoundry/scripts/zetdisplay.sh");
?>
</pre>