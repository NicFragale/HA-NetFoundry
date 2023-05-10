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
            hr {margin: 0;}
            #BODYIMG {
                background: url(images/logo.png) no-repeat center center fixed;
                min-height: 100%;
                min-width: 100px;
                width: 100%;
                height: auto;
                position: fixed;
                top: 0;
                left: 0;
                z-index: -1;
            }
            @media screen and (max-width: 400px) {#BODYIMG {left: 50%; margin-left: -200px;}}
            .BODYWHITE {background-color: white; color: black;}
            .BODYBLACK {background-color: black; color: white;}
            .NOTVISIBLE {display: none;}
            .OPACITY-A {opacity: 1;}
            .OPACITY-B {opacity: 0.85;}
            .OPACITY-C {opacity: 0.5;}
            .OPACITY-D {opacity: 0.15;}
            .OPACITY-E {opacity: 0;}
            .CENTERDATE, .CENTERINFO {text-align: center;}
            .CENTERDATE {float: right;}
            .FULLWIDTH {width: 100%; float: left;}
            .FG-BOLD {font-weight: bold;}
            .FG-LARGE {font-size: 2.5vmin;}
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
            .ANIMATED {transition: all ease;}
            .T500MS {transition-duration: 1s;}
            .T1S {transition-duration: 1s;}
            .T2S {transition-duration: 2s;}
            .T3S {transition-duration: 3s;}
        </style>
    </head>
    <body>
        <script>
            // Global variables declaration.
            var waitInt, currentTime, currentHour, setBG_AllFGClasses, setBG_AllFGLength;

            // Set the background color according to the time of day.
            function UpdatePageColors() {
                currentTime = new Date();
                currentHour = currentTime.getHours();
                if ((currentHour < 8) || (currentHour > 20)) {
                    $("body").removeClass("BODYWHITE").addClass("BODYBLACK");
                    setBG_AllFGClasses = new Array ('FG-GRAY','FG-WHITE');
                } else {
                    $("body").removeClass("BODYBLACK").addClass("BODYWHITE");
                    setBG_AllFGClasses = new Array ('FG-BLACK','FG-GRAY','FG-RED','FG-GREEN','FG-BLUE','FG-PURPLE');
                }
                setBG_AllFGLength = setBG_AllFGClasses.length;
            }

            // Update ZET information on the page.
            function UpdateZETInfo() {
                waitInt = 0;
                $.ajax({
                    url: 'zetdisplay.php',
                    success: function(UpdateDetails) {
                        $("#ZETDETAIL").fadeOut(200).promise().done(function() {
                            $("#ZETLOAD").empty().removeClass("CENTERINFO").append(UpdateDetails);
                            $("#ZETDETAIL").children().hide().each(function() {
                                $(this).delay(waitInt+=25).slideDown();
                            });
                        });
                    }
                });
            }

            // Page is ready, begin with oneshot actions.
            $(document).ready(function(){
                $("#BODYIMG").fadeIn();
                $("#ZETLOAD").fadeIn();
                $.ajax({
                    url: 'infodisplay.php',
                    success: function(UpdateInfo) {
                        $("#INFOLOAD").addClass("NOTVISIBLE").empty().append(UpdateInfo).promise().done(function() {
                            $("#OPENZITITEXT").addClass(setBG_AllFGClasses[Math.floor(Math.random()*setBG_AllFGLength)]);
                            $("#INFOLOAD").slideDown(1000);
                            setTimeout(function() {
                                $("#OPENZITITEXT").slideUp();
                                $("#BODYIMG").addClass("OPACITY-D");
                                $("#OPENZITIVERSION").addClass("FG-BOLD FG-LARGE FG-BLUE");
                            }, 8000);
                        });
                    }
                });

                // Interval based actions.
                setInterval(function() {
                    UpdatePageColors
                }, 30000);
                setInterval(function() {
                    UpdateZETInfo
                }, 5000);
            });
        </script>
        <div id="BODYIMG" class="ANIMATED T2S OPACITY-C"></div>
        <div id="INFOLOAD" class="CENTERINFO FULLWIDTH"><span></span></div>
        <div id="ZETLOAD" class="CENTERINFO FULLWIDTH"><span class="FG-BLACK BG-YELLOW">INITIALIZING, PLEASE WAIT</span></div>
    </body>
</html>