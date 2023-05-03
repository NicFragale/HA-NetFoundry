<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="application/xml+xhtml; charset=UTF-8"/>
        <title>NetFoundry OpenZITI (ZITI EDGE TUNNEL) Status Page</title>
        <script src="jquery-3.6.4.min.js"></script>
        <style type="text/css">
            body {
                font-family: monospace;
                height: 100%;
                width: 100%;
                padding: 0px;
                margin: 0px;
                white-space: nowrap;
                font-size: 1.5vmin;
            }
            #BODYIMG {
                background: url(images/logo.png) no-repeat center center fixed;
                min-height: 100%;
                min-width: 400px;
                width: 100%;
                height: auto;
                position: fixed;
                top: 0;
                left: 0;
                opacity: 1;
                z-index: -1;
            }
            @media screen and (max-width: 400px) {#BODYIMG {left: 50%; margin-left: -200px;}}
            .BODYWHITE {background-color: white; color: black;}
            .BODYBLACK {background-color: black; color: white;}
            .NOTVISIBLE {display: none;}
            .CENTERDATE, .CENTERINFO {text-align: center;}
            .CENTERDATE {float: right;}
            .FULLWIDTH {width: 100%; float: left;}
            .FG-BOLD {font-weight: bold;}
            .FG-GRAY {color: gray;}
            .FG-WHITE {color: white;}
            .FG-BLACK {color: black;}
            .FG-YELLOW {color: yellow;}
            .FG-RED {color: red;}
            .FG-GREEN {color: green;}
            .FG-BLUE {color: blue;}
            .FG-PURPLE {color: purple;}
            .BG-GRAY {background-color: gray;}
            .BG-WHITE {background-color: white;}
            .BG-BLACK {background-color: black;}
            .BG-YELLOW {background-color: yellow;}
            .BG-RED {background-color: red;}
            .BG-GREEN {background-color: green;}
            .BG-BLUE {background-color: blue;}
            .BG-PURPLE {background-color: purple;}
        </style>
    </head>
    <body>
        <script>
            var currentTime = new Date();
            var currentHour = currentTime.getHours();
            var waitInt;
            if ((currentHour < 8) || (currentHour > 20)) {
                $("body").addClass("BODYBLACK");
            } else {
                $("body").addClass("BODYWHITE");
            }
            $(document).ready(function(){
                $("#INFOLOAD").load('infodisplay.php').delay(100).slideDown().promise().done(function(){
                    $("#OPENZITITEXT").delay(5000).slideUp().promise().done(function(){
                        $("#BODYIMG").delay().animate({
                            opacity: 0.15
                        }, 2000);
                    });
                });
                $("#ZETLOAD").delay(500).slideDown().promise().done(function(){
                    $("#ZETLOAD").removeClass("NOTVISIBLE");
                    setInterval(function(){
                        waitInt = 0;
                        $.ajax({
                            url: 'zetdisplay.php',
                            success: function(UpdateDetails) {
                                $("#ZETDETAIL").fadeOut(200).promise().done(function(){
                                    $("#ZETLOAD").empty().append(UpdateDetails);
                                    $("#ZETDETAIL").children().hide().each(function(){
                                        $(this).delay(waitInt+=25).slideDown();
                                    });
                                });
                            }
                        });
                    }, 5000);
                });
            });
        </script>
        <div id="BODYIMG"></div>
        <div id="INFOLOAD" class="CENTERINFO FULLWIDTH NOTVISIBLE"><span class="FG-BLACK BG-YELLOW">INITIALIZING, PLEASE WAIT</span></div>
        <div id="ZETLOAD" class="FULLWIDTH NOTVISIBLE"><span class="FG-BLACK BG-YELLOW">INITIALIZING, PLEASE WAIT</span></div>
    </body>
</html>