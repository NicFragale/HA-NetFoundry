<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="application/xml+xhtml; charset=UTF-8"/>
        <!--<meta http-equiv="refresh" content="5">-->
        <title>NetFoundry OpenZITI (ZITI EDGE TUNNEL) Status Page</title>
        <script src="jquery-3.6.4.min.js"></script>
        <style type="text/css">
            body {
                background-color: white;
                color: black;
            }
            pre {
                white-space: pre-wrap; white-space: -moz-pre-wrap !important;
                white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word;
            }
            .NOTVISIBLE {
                display: none;
            }
            .CENTERDATE, .CENTERINFO {
                text-align: center;
            }
        </style>
    </head>
    <body>
        <script>
            var currentTime = new Date();
            var hours = currentTime.getHours();
            if ((hours < 8) || (hours > 20)) {
                $("body").css("background-color","black").css("color","white");
            }
            $(document).ready(function(){
                setInterval(function(){
                    $.ajax({
                        url: 'zetdisplay.php',
                        success: function(data) {
                            $("#ZETDETAIL").fadeOut(200).promise().done(function(){
                                $("#ZETLOAD").html(data);
                                $("#ZETDETAIL").hide().slideDown(200);
                            });
                        }
                    });
                }, 5000);
                $("#INFO").hide().slideDown().delay(5000).slideUp();
                $("#ZETLOAD").hide().slideDown();
            });
        </script>
        <div id="INFO" class="CENTERINFO NOTVISIBLE">
            <pre>
<?php
echo shell_exec("/usr/bin/sudo /opt/NetFoundry/scripts/infodisplay.sh STATUS");
?>
            </pre>
        </div>
        <div id="ZETLOAD" class="NOTVISIBLE"></div>
    </body>
</html>