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
            #ZETLOADSTATUS {line-height: 5em; cursor: pointer;}
            .BODYOVERLAY {height: 100%; width: 100%; position: fixed;}
            .BODYWHITE {background: white; text-shadow: 0px 0px 1px white;}
            .BODYBLACK {background: black; text-shadow: 0px 0px 1px black;}
            .NOTVISIBLE {display: none;}
            .FG-SHADOW {text-shadow: 0px 0px 3px blue;}
            .OPACITY-A {opacity: 1;}
            .OPACITY-B {opacity: 0.85;}
            .OPACITY-C {opacity: 0.5;}
            .OPACITY-D {opacity: 0.15;}
            .OPACITY-E {opacity: 0;}
            .CENTERDATE, .CENTERINFO {text-align: center;}
            .CENTERDATE {float: right;}
            .FULLWIDTH {width: 100%; float: left;}
            .FG-BOLD {font-weight: bold;}
            .FG-ITALIC {font-style: italic;}
            .FG-LARGE {font-size: 2.5vmin;}
            .FG-GREY {color: grey;}
            .FG-LTGREY {color: lightgrey;}
            .FG-WHITE {color: white;}
            .FG-BLACK {color: black;}
            .FG-YELLOW {color: yellow;}
            .FG-RED {color: red;}
            .FG-GREEN {color: green;}
            .FG-BLUE {color: blue;}
            .FG-PURPLE {color: purple;}
            .BG-GREY {background-color: grey;}
            .BG-LTGREY {background-color: lightgrey;}
            .BG-WHITE {background-color: white;}
            .BG-BLACK {background-color: black;}
            .BG-YELLOW {background-color: yellow;}
            .BG-RED {background-color: red;}
            .BG-GREEN {background-color: green;}
            .BG-BLUE {background-color: blue;}
            .BG-PURPLE {background-color: purple;}
            .BG-NONE {background-color: unset;}
            .ANIMATED {transition: all ease;}
            .T25MS {transition-duration: 0.025s;}
            .T100MS {transition-duration: 0.1s;}
            .T500MS {transition-duration: 0.5s;}
            .T1S {transition-duration: 1s;}
            .T2S {transition-duration: 2s;}
            .T3S {transition-duration: 3s;}
        </style>
    </head>
    <body>
        <script>
            // Global variables declaration.
            var flagPause, waitInt, currentTime, currentHour, setColor_AllFGClasses, setColor_AllFGLength;

            // Set the background color according to the time of day.
            function UpdatePageColors() {
                currentTime = new Date();
                currentHour = currentTime.getHours();
                if ((currentHour < 8) || (currentHour > 20)) {
                    $("#BODYPARENT").removeClass("BODYWHITE").addClass("BODYBLACK");
                    $("body").removeClass().addClass("FG-WHITE");
                    setColor_AllFGClasses = new Array ('FG-GREY','FG-WHITE');
                } else {
                    $("#BODYPARENT").removeClass("BODYBLACK").addClass("BODYWHITE");
                    $("body").removeClass().addClass("FG-BLACK");
                    setColor_AllFGClasses = new Array ('FG-BLACK','FG-GREY','FG-RED','FG-GREEN','FG-BLUE','FG-PURPLE');
                }
                setColor_AllFGLength = setColor_AllFGClasses.length;
                $("#OPENZITITEXT").removeClass().addClass("FG-SHADOW " + setColor_AllFGClasses[Math.floor(Math.random()*setColor_AllFGLength)]);
            }

            // Update ZET information on the page.
            function UpdateZETInfo() {
                waitInt = 0;
                if ($("#ZETLOADSTATUS").hasClass("NOTVISIBLE")) {
                    flagPause = "UNSET";
                } else {
                    flagPause = "SET";
                }
                $.ajax({
                    url: 'zetdisplay.php',
                    data: {'flagPause': flagPause},
                    success: function(UpdateDetails) {
                        if (flagPause == "SET") {
                            $("#ZETDATE-BROWSER").replaceWith(UpdateDetails);
                        } else {
                            $("#ZETDETAIL").fadeOut(200).promise().done(function() {
                                $("#ZETLOAD").empty().removeClass("CENTERINFO").append(UpdateDetails);
                                $(".ZETDETAILLINE").hide().addClass("ANIMATED T500MS BG-YELLOW").each(function() {
                                    $(this).delay(waitInt+=50).slideDown(25).promise().done(function() {
                                        $(this).removeClass("BG-YELLOW");
                                    });
                                });
                            });
                        }
                    }
                });
            }

            // Page is ready, begin with oneshot actions.
            $(document).ready(function(){
                $("#BODYPARENT").fadeIn();
                $.ajax({
                    url: 'infodisplay.php',
                    success: function(UpdateInfo) {
                        $("#INFOLOAD").addClass("NOTVISIBLE").empty().append(UpdateInfo).promise().done(function() {
                            $("#INFOLOAD").slideDown(1000);
                            UpdatePageColors();
                            setTimeout(function() {
                                $("#OPENZITITEXT").slideUp();
                                $("#BODYIMG").removeClass("OPACITY-C").addClass("OPACITY-D");
                                $("#OPENZITIVERSION").addClass("FG-BOLD FG-LARGE FG-BLUE");
                                $("body").on("click", function() {
                                    $("#ZETLOADSTATUS").fadeToggle().promise().done(function() {
                                        $("#ZETLOADSTATUS").toggleClass("NOTVISIBLE");
                                    });
                                });
                            }, 8000);
                        });
                    }
                });

                // Setup click and interval based actions.
                setInterval(function() {
                    UpdatePageColors();
                }, 30000);
                setInterval(function() {
                    if ($("#ZETLOADSTATUS").is(":visible")) {
                        UpdatePageColors();
                        $("#OPENZITITEXT").slideDown();
                    } else {
                        $("#OPENZITITEXT").slideUp();
                    }
                    UpdateZETInfo();
                }, 8000);
            });
        </script>
        <div id="BODYPARENT" class="BODYOVERLAY NOTVISIBLE">
            <span id="INFOLOAD" class="CENTERINFO FULLWIDTH"></span>
            <span id="ZETLOADSTATUS" class="CENTERINFO FULLWIDTH NOTVISIBLE FG-BOLD FG-LARGE FG-BLACK BG-YELLOW">REFRESH PAUSED - CLICK TO RESUME</span>
            <span id="ZETLOAD" class="CENTERINFO FULLWIDTH">
                <span class="FULLWIDTH FG-BLACK BG-YELLOW">INITIALIZING, PLEASE WAIT</span>
            </span>
            <span id="BODYIMG" class="ANIMATED T2S OPACITY-C"></span>
        </div>
    </body>
</html>