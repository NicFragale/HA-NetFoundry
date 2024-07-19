#!/usr/bin/with-contenv bashio
####################################################################################################
# 20240701 - Written by Nic Fragale @ NetFoundry.
MyName="zetdisplay.sh"
MyPurpose="Ziti-Edge-Tunnel Runtime Display."
####################################################################################################
#set -e -u -o pipefail
[[ ${ZITI_ENV_LOG:-INFO} == "DEBUG" ]] &&
	bashio::log.info "MyName: ${MyName}" &&
	bashio::log.info "MyPurpose: ${MyPurpose}"

####################################################################################################
# Functions
####################################################################################################
function ZET_Status() {
	local ZETSocksDir="/tmp/.ziti"
	local ZETSock="${ZETSocksDir}/ziti-edge-tunnel.sock"
	local ZETResults

	# Find the ZET socket or die.
	if [[ ! -e ${ZETSock} ]]; then
		ZETSock="$(find / -name ziti-edge-tunnel.sock 2>/dev/null)"
		if [[ -e ${ZETSock} ]]; then
			ZETSocksDir="${ZETSock%\/*}"
		else
			printf "<span class=\"FG-BLACK BG-YELLOW\">%s</span></span><br>" "The ZITI-EDGE-TUNNEL socket is not available. Please wait or restart."
			return
		fi
	fi

	# Set the directory to work from.
	local QueryCommand="{\"Command\":\"ZitiDump\",\"Data\":{\"DumpPath\":\"${ZETSocksDir}\"}}"

	# Check for the presence of the socket that ZET creates when running.
	if [[ -e "${ZETSock}" ]]; then

		# Send the command to the ZET socket and get the result.
		echo "${QueryCommand}" | socat - UNIX-CONNECT:"${ZETSock}" >/dev/null
		readarray -t ZETResults < <(find "${ZETSocksDir}"/*.ziti -type f 2>/dev/null)

		# Initial analysis.
		if [[ ${#ZETResults[*]} -lt 1 ]]; then
			printf "<span class=\"FG-BLACK BG-YELLOW\">%s</span></span><br>" "The query resulted in no data."
			return
		fi

		# Begin the analysis and output it.
		for ((i = 0; i < ${#ZETResults[*]}; i++)); do

			awk -v ZITICONTEXT_COUNTER="$((i + 1))" -v ZITICONTEXT_COUNTEREND="${#ZETResults[*]}" '

				function PRINTLINE(LBRTYPE, LABELCOLORA, LABELCOLORB, LABEL, SUBLABEL, CONTEXT) {
					COMMONLINE="GREEN"
					printf "<span class=\"ZETDETAILLINE FULLWIDTH\">"
					switch (LBRTYPE) {
						case "SINGLELBR":
							printf "<span class=\"FG-"COMMONLINE"\">┃</span>"
							break
						case "HEAD":
							printf "<span class=\"FG-"COMMONLINE"\">┏</span><span class=\"FG-%s BG-%s\"><pre>%s</pre></span>",LABELCOLORA,LABELCOLORB,LABEL
							break
						case "TAIL":
							printf "<span class=\"FG-"COMMONLINE"\">┗</span><span class=\"FG-%s BG-%s\">%s</pre></span>",LABELCOLORA,LABELCOLORB,LABEL
							break
						case "INITIAL":
							printf "<span class=\"FG-"COMMONLINE"\">┣┳</span><span class=\"FG-%s BG-%s\"><pre>%-13.13s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
						case "FINAL":
							printf "<span class=\"FG-"COMMONLINE"\">┃┗━</span><span class=\"FG-%s BG-%s\"><pre>%-12.12s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
						case "BRANCHNORMAL":
							printf "<span class=\"FG-"COMMONLINE"\">┃┣━</span><span class=\"FG-%s BG-%s\"><pre>%-12.12s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
						case "BRANCHTOSUB":
							printf "<span class=\"FG-"COMMONLINE"\">┃┣┳</span><span class=\"FG-%s BG-%s\"><pre>%-12.12s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
						case "SUBBRANCH":
							printf "<span class=\"FG-"COMMONLINE"\">┃┃┗━</span><span class=\"FG-%s BG-%s\"><pre>%-11.11s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
						case "DOUBLELBR":
							printf "<span class=\"FG-"COMMONLINE"\">┃┃</span><span class=\"FG-%s BG-%s\"><pre>%-13.13s</pre></span> <span class=\"FG-ITALIC\"><pre>%-12.12s</pre></span><span>%s</span>",LABELCOLORA,LABELCOLORB,LABEL,SUBLABEL,CONTEXT
							break
					}
					printf "</span><br>"
				}

				function JOINARRAY(INPUTARRAY, DELIM, RESULTSCALAR) {
					if (DELIM == "")
						DELIM = " "
					else if (DELIM == SUBSEP)
						DELIM = ""

					i=1
					for (EACHELEMENT in INPUTARRAY) {
						if (i<=length(INPUTARRAY) && i==1) {
							RESULTSCALAR = INPUTARRAY[EACHELEMENT]
						} else if (i<=length(INPUTARRAY)) {
							RESULTSCALAR = RESULTSCALAR DELIM INPUTARRAY[EACHELEMENT]
						}
						i+=1
					}
					return RESULTSCALAR
				}

				function CONCATARRAY(ARRAY_A,ARRAY_B,ARRAY_C) {
					ARRAY_GLOBALCOUNTER=0
					for (i in ARRAY_A) {
						ARRAY_C[++ARRAY_GLOBALCOUNTER]=ARRAY_A[i]
					}
					for (i in ARRAY_B) {
						ARRAY_C[++ARRAY_GLOBALCOUNTER]=ARRAY_B[i]
					}
				}

				function READYSAVE(SAVE_SWITCHING) {
					if (SAVE_SWITCHING == "ZITICONTEXT" ) {
						ZITICONTEXT_REPORT[++ZITICONTEXTS]=ZITI_IDENTITYNAME","ZITI_IDENTITY
					} else if (SAVE_SWITCHING == "SERVICES" ) {
						if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
							SERVICE_DIALREPORT[++INCRD]=SERVICE_IDENTITY","SERVICE_TYPE","SERVICE_NAME","SERVICE_CLIENTFULLHOST","SERVICE_SERVERFULLHOST
						} else if (SERVICE_TYPE == "BINDONLY") {
							SERVICE_BINDREPORT[++INCRB]=SERVICE_IDENTITY","SERVICE_TYPE","SERVICE_NAME","SERVICE_CLIENTFULLHOST","SERVICE_SERVERFULLHOST
						}
					} else if (SAVE_SWITCHING == "CONNECTIONS" ) {
						CONNECTION_REPORT[++CONNECTION_COUNTER]=CONNECTION_NUMBER","CONNECTION_SERVICENAME","CONNECTION_TERMINATORS
					} else if (SAVE_SWITCHING == "CHILDREN" ) {
						CHILDREN_REPORT[++CHILD_COUNTER]=CONNECTION_CHILDTOCONNECTIONNUMBER","CONNECTION_CHILDNUMBER","toupper(CONNECTION_CHILDSTATE)","CONNECTION_CHILDCALLERID","CONNECTION_CHILDCHANNELROUTER","CONNECTION_CHILDINFO_A","CONNECTION_CHILDINFO_B
					} else if (SAVE_SWITCHING == "CHANNELS" ) {
						CHANNEL_REPORT[++CHANNEL_COUNTER]=CHANNEL_NUMBER","CHANNEL_ROUTER","toupper(CHANNEL_STATE)","CHANNEL_LATENCY
					} else if (SAVE_SWITCHING == "NETSESSIONS" ) {
						NETSESSION_REPORT[++NETSESSION_COUNTER]=NETSESSION_ID","NETSESSION_SERVICEID
					}
				}

				function CONCLUDESECTION(a,b) {
					if (a == "ZITICONTEXT") {
						READYSAVE("ZITICONTEXT")
					} else if (a == "SESSION") {
					} else if (a == "SESSIONINFO") {
					} else if (a == "SERVICES") {
						READYSAVE("SERVICES")
					} else if (a == "NETSESSIONS") {
					} else if (a == "CHANNELS") {
					} else if (a == "CONNECTIONS") {
					} else if (a == "CHILDREN") {
					}
					return b
				}

				BEGIN {
					CURRENTSECTION="INIT"
					ARRAY_GLOBALCOUNTER=0
					CONNECTION_COUNTER=0
					CHILD_COUNTER=0
					CHANNEL_COUNTER=0
					NETSESSION_COUNTER=0
					CHANNEL_ORPHANCOUNTER=0
				}

				{
					# Section Switching.
					if (/^Ziti Context:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"ZITICONTEXT")
					} else if (/^Session:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SESSION")
					} else if (/^Session Info:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SESSIONINFO")
					} else if (/^Services:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"SERVICES")
					} else if (/^Net Sessions:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"NETSESSIONS")
					} else if (/^Channels:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"CHANNELS")
					} else if (/^Connections:$/) {
						CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"CONNECTIONS")
					}

					# ZITI CONTEXT SECTION #
					if (/^Identity:/) {

						ZITI_IDENTITYNAME=gensub(/Identity:[[:space:]]+(.*)\[.*/,"\\1","1")
						ZITI_IDENTITY=gensub(/.*\[(.*)\]/,"\\1","1")

					# SERVICES SECTION #
					} else if (/dial=.*,bind=.*/) {

						if (SERVICE_TYPE)
							READYSAVE("SERVICES")
						if (/dial=true,bind=false/) {
							SERVICE_TYPE="DIALONLY"
						} else if (/dial=false,bind=true/) {
							SERVICE_TYPE="BINDONLY"
						} else if (/dial=true,bind=true/) {
							SERVICE_TYPE="DIALBIND"
						}

						SERVICE_NAME=gensub(/(.*):.*/,"\\1","1")
						SERVICE_IDENTITY=gensub(/.*\[(.*)\].*/,"\\1","1")

					} else if (/\[host.v.\]/) {
						if (/\"allowedAddresses\"/) {
							SERVICE_SERVERHOST=gensub(/.*\"allowedAddresses\":(\[[^,]+)[^\]]+,.*/,"\\1","1")
						} else {
							SERVICE_SERVERHOST=gensub(/.*\"address\":\"(.*)\",.*/,"\\1","1")
						}

						if (/\"allowedPortRanges\"/) {
							SERVICE_SERVERPORT=gensub(/.*\"high\":([0-9]+),\"low\":([0-9]+).*/,"\\2-\\1","G")
						} else {
							SERVICE_SERVERPORT=gensub(/.*\"port\":(.*),.*/,"\\1","1")
						}

						if (/\"allowedProtocols\"/) {
							SERVICE_SERVERPROTOCOL=gensub(/.*\"allowedProtocols\":\[(.*)\],.*/,"\\1","1")
						} else {
							SERVICE_SERVERPROTOCOL=gensub(/.*\"protocol\":\"(.*)\".*/,"\\1","1")
						}
						gsub(/,/,"+",SERVICE_SERVERPROTOCOL) # Change comma to plus.

						SERVICE_SERVERFULLHOST=SERVICE_SERVERHOST":["SERVICE_SERVERPORT"]/["SERVICE_SERVERPROTOCOL"]"
						gsub(/,/," ",SERVICE_SERVERFULLHOST)
						gsub(/\"/,"",SERVICE_SERVERFULLHOST)

						if (/\"forwardPort\":true/) {
							SERVICE_SERVERFORWARDPORT="<span class=\"FG-GREEN\">YES</span>"
						} else {
							SERVICE_SERVERFORWARDPORT="<span class=\"FG-GREY\">NO</span>"
						}

						if (/\"forwardProtocol\":true/) {
							SERVICE_SERVERFORWARDPROTOCOL="<span class=\"FG-GREEN\">YES</span>"
						} else {
							SERVICE_SERVERFORWARDPROTOCOL="<span class=\"FG-GREY\">NO</span>"
						}

						SERVICE_SERVERFULLHOST=SERVICE_SERVERFULLHOST" (FWDPORT="SERVICE_SERVERFORWARDPORT") (FWDPROTO="SERVICE_SERVERFORWARDPROTOCOL")"

					} else if (/\[intercept.v1\]/) {

						SERVICE_CLIENTHOST=gensub(/.*\"addresses\":\[([^\]]+)\].*/,"\\1","1")
						split(SERVICE_CLIENTHOST,ARRAY_CLIENTHOSTS,",")
						for (EACH_CLIENTHOST in ARRAY_CLIENTHOSTS) {
							gsub(/\"/,"",ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]) # Remove double quotes.
							FINALRESOLVE=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]
							gsub(/\*\.?/,"",FINALRESOLVE) # Remove star domains.
							if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
								if (match(ARRAY_CLIENTHOSTS[EACH_CLIENTHOST],/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]="["ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"]@IPONLY"
								} else {
									RUNCOMMAND = "echo -n TRYDNS:$(dig +short "FINALRESOLVE" 2>&1)"
									RUNCOMMAND | getline EACH_CLIENTHOSTRESOLVED
									close(RUNCOMMAND)
									gsub(/ /,"|",EACH_CLIENTHOSTRESOLVED)
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]="["ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"]@"EACH_CLIENTHOSTRESOLVED
								}
							} else {
								ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]="["ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"]"
							}
						}

						SERVICE_CLIENTHOST=JOINARRAY(ARRAY_CLIENTHOSTS)
						SERVICE_CLIENTPORT=gensub(/.*\"high\":([0-9]+),\"low\":([0-9]+).*/,"\\2-\\1","G")
						SERVICE_CLIENTPROTOCOL=gensub(/.*\"protocols\":\[(\".*\")\]\}/,"\\1","1")
						gsub(/\"/,"",SERVICE_CLIENTPROTOCOL) # Remove double quotes.
						gsub(/,/,"+",SERVICE_CLIENTPROTOCOL) # Change comma to plus.
						SERVICE_CLIENTFULLHOST=SERVICE_CLIENTHOST"=["SERVICE_CLIENTPORT"]/["SERVICE_CLIENTPROTOCOL"]"

					} else if (/\[ziti-tunneler-server.v1\]/) {

						SERVICE_SERVERHOST=gensub(/.*\"hostname\":\"(.*)\",.*/,"\\1","1")
						SERVICE_SERVERPORT=gensub(/.*\"port\":(.*),?.*/,"\\1","1")
						SERVICE_SERVERPROTOCOL=gensub(/.*\"protocol\":\"(.*)\"}/,"\\1","1")
						SERVICE_SERVERFULLHOST=SERVICE_SERVERHOST":"SERVICE_SERVERPORT"/"SERVICE_SERVERPROTOCOL

					} else if (/\[ziti-tunneler-client.v1\]/) {

						SERVICE_CLIENTHOST=gensub(/.*\"hostname\":\"(.*)\",.*/,"\\1","1")
						SERVICE_CLIENTPORT=gensub(/.*\"port\":(.*)}/,"\\1","1")
						SERVICE_CLIENTFULLHOST=SERVICE_CLIENTHOST":"SERVICE_CLIENTPORT

						if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
							if (match(SERVICE_CLIENTHOST,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
								SERVICE_CLIENTHOSTRESOLVED="IPONLY"
							} else {
								RUNCOMMAND = "echo -n TRYDNS:$(dig +short "SERVICE_CLIENTHOST" 2>&1)"
								RUNCOMMAND | getline SERVICE_CLIENTHOSTRESOLVED
								close(RUNCOMMAND)
								gsub(/ /," || ",SERVICE_CLIENTHOSTRESOLVED)
							}
						}

					} else if (/posture/) {

					# NET SESSIONS SECTION #
					} else if (/service_id/) {

						NETSESSION_ID=gensub(/^(.*):.*/,"\\1","1")
						NETSESSION_SERVICEID=gensub(/.*service_id\[(.*)\]/,"\\1","1")
						READYSAVE("NETSESSIONS")

					# CONNECTIONS SECTION #
					} else if (/conn\[.*\]/) {

						CONNECTION_NUMBER=gensub(/^conn\[(.*)\]: .*/,"\\1","1")
						CONNECTION_SERVICENAME=gensub(/.*service\[(.*)\] .*/,"\\1","1")
						CONNECTION_TERMINATORS=gensub(/.*terminators\[(.*)\]/,"\\1","1")
						READYSAVE("CONNECTIONS")

					# CONNECTIONS/CHILDREN SUBSECTION #
					} else if (/child\[.*\]/) {

						CONNECTION_CHILDTOCONNECTIONNUMBER=CONNECTION_NUMBER
						CONNECTION_CHILDNUMBER=gensub(/.*child\[(.*)\/-\]:.*/,"\\1","1")
						CONNECTION_CHILDSTATE=gensub(/.*state\[(.*)\] caller_id.*/,"\\1","1")
						CONNECTION_CHILDCALLERID=gensub(/.*caller_id\[(.*)\] ch.*/,"\\1","1")
						CONNECTION_CHILDCHANNELROUTER=gensub(/.*ch\[(.*)\/.*\]/,"\\1","1")
						getline
						CONNECTION_CHILDINFO_A=gensub(/^[[:blank:]]+(.*)/,"\\1","1")
						getline
						CONNECTION_CHILDINFO_B=gensub(/^[[:blank:]]+bridge: (.*)/,"\\1","1")
						READYSAVE("CHILDREN")

					# CHANNELS SECTION #
					} else if (/ch\[.*\]/) {

						CHANNEL_NUMBER=gensub(/^ch\[(.*)\]\(.*/,"\\1","1")
						CHANNEL_ROUTER=gensub(/ch\[.*\]\((.*)\).*/,"\\1","1")
						if (match($0,"latency")) {
							CHANNEL_STATE=gensub(/.*\) (.*) \[.*/,"\\1","1")
							CHANNEL_LATENCY=gensub(/.*\[latency=(.*)\].*/,"\\1","1")
						} else {
							CHANNEL_STATE=gensub(/.*\) (.*).*/,"\\1","1")
							CHANNEL_LATENCY="NA"
						}
						READYSAVE("CHANNELS")

					}

				}

				END {
					CURRENTSECTION=CONCLUDESECTION(CURRENTSECTION,"END")

					# Print ZITICONTEXT first.
					# For every ZITICONTEXT.
					for (EACH_ZITICONTEXT in ZITICONTEXT_REPORT) {
						# ZITICONTEXTS # [1]=IDNAME,[2]=ID
						split(ZITICONTEXT_REPORT[EACH_ZITICONTEXT],PRINT_ZITICONTEXT,",")
						PRINTLINE("HEAD","GREEN","NONE",sprintf("%02d/%s/%s",ZITICONTEXT_COUNTER,PRINT_ZITICONTEXT[2],PRINT_ZITICONTEXT[1]))
						PRINTLINE("SINGLELBR")
					}

					# Combine the SERVICE arrays in proper order and sorting.
					CONCATARRAY(SERVICE_DIALREPORT,SERVICE_BINDREPORT,SERVICE_REPORT)
					# Loop all SERVICES.
					for (EACH_SERVICE = 1; EACH_SERVICE <= ARRAY_GLOBALCOUNTER; EACH_SERVICE++) {

						# SERVICES # [1]=ID,[2]=TYPE,[3]=NAME,[4]=INADDR@RESOLVED,[5]=OUTADDR
						split(SERVICE_REPORT[EACH_SERVICE],PRINT_SERVICE,",")

						# If the user passed in a filter, and that filter is not matched here, continue past this service.
						if (FILTER) {
							SERVICELINE=EACH_SERVICE"/"PRINT_SERVICE[2]"/"PRINT_SERVICE[1]"/"PRINT_SERVICE[3]
							if (SERVICELINE !~ FILTER) continue
						}

						# First output line with service information.
						PRINTLINE("INITIAL","NONE","NONE",sprintf("%04d",EACH_SERVICE),"SERVICE",PRINT_SERVICE[3]" ("PRINT_SERVICE[2]")")

						# Net Sessions, Service Authorization token assessment.
						NETSESSION_FOUNDSEMAPHORE="FALSE"
						# For every SERVICE, loop all NETSESSIONS.
						for (EACH_NETSESSIONSERVICE in NETSESSION_REPORT) {

							# NET SESSIONS # [1]=ID,[2]=SERVICEID
							split(NETSESSION_REPORT[EACH_NETSESSIONSERVICE],PRINT_NETSESSION,",")
							if (PRINT_NETSESSION[2] == PRINT_SERVICE[1]) {
								NETSESSION_FOUNDSEMAPHORE="TRUE"
								break
							}

						}

						# Service type output with color indicator for local applicability.
						if (PRINT_SERVICE[2] == "DIALONLY") {
							SERVICE_INGRESSTYPE="●INGRESS"
							SERVICE_EGRESSTYPE="▷EGRESS"
							SERVICE_INGRESSTYPE_COLORFG="GREEN"
							SERVICE_INGRESSTYPE_COLORBG="NONE"
							SERVICE_EGRESSTYPE_COLORFG="GREY"
							SERVICE_EGRESSTYPE_COLORBG="NONE"
						} else if (PRINT_SERVICE[2] == "DIALBIND") {
							SERVICE_INGRESSTYPE="●INGRESS"
							SERVICE_EGRESSTYPE="▶EGRESS"
							SERVICE_INGRESSTYPE_COLORFG="GREEN"
							SERVICE_INGRESSTYPE_COLORBG="NONE"
							SERVICE_EGRESSTYPE_COLORFG="GREEN"
							SERVICE_EGRESSTYPE_COLORBG="NONE"
						} else if (PRINT_SERVICE[2] == "BINDONLY") {
							SERVICE_INGRESSTYPE="○INGRESS"
							SERVICE_EGRESSTYPE="▶EGRESS"
							SERVICE_INGRESSTYPE_COLORFG="GREY"
							SERVICE_INGRESSTYPE_COLORBG="NONE"
							SERVICE_EGRESSTYPE_COLORFG="GREEN"
							SERVICE_EGRESSTYPE_COLORBG="NONE"
						}

						# Match the SERVICE_TYPE.
						if (PRINT_SERVICE[2] == "DIALONLY" || PRINT_SERVICE[2] == "DIALBIND") {

							if (NETSESSION_FOUNDSEMAPHORE == "TRUE") {
								PRINTLINE("BRANCHNORMAL","GREEN","NONE","SESSAUTH","TOKEN",PRINT_NETSESSION[1])
							} else {
								PRINTLINE("BRANCHNORMAL","RED","NONE","SESSAUTH","TOKEN","NOT PRESENT")
							}

							# Match the SERVICE_INADDR@RESOLVED.
							split(PRINT_SERVICE[4],ARRAY_CLIENTHOSTS,"=")
							split(ARRAY_CLIENTHOSTS[1],ARRAY_CLIENTHOSTRESOLUTIONS," ")
							for (EACH_CLIENTHOSTRESOLUTION in ARRAY_CLIENTHOSTRESOLUTIONS) {
								split(ARRAY_CLIENTHOSTRESOLUTIONS[EACH_CLIENTHOSTRESOLUTION],NAMEANDRESOLUTION,"@")
								if (NAMEANDRESOLUTION[2] == "TRYDNS:") {
									PRINTLINE("BRANCHTOSUB",SERVICE_INGRESSTYPE_COLORFG,SERVICE_INGRESSTYPE_COLORBG,SERVICE_INGRESSTYPE,"INTERCEPTS",NAMEANDRESOLUTION[1]":"ARRAY_CLIENTHOSTS[2])
									PRINTLINE("SUBBRANCH","RED","NONE","UNRESOLVABLE")
								} else if (NAMEANDRESOLUTION[2] == "IPONLY") {
									PRINTLINE("BRANCHNORMAL",SERVICE_INGRESSTYPE_COLORFG,SERVICE_INGRESSTYPE_COLORBG,SERVICE_INGRESSTYPE,"INTERCEPTS",NAMEANDRESOLUTION[1]":"ARRAY_CLIENTHOSTS[2])
								} else {
									gsub(/TRYDNS:/,"",NAMEANDRESOLUTION[2])
									PRINTLINE("BRANCHTOSUB",SERVICE_INGRESSTYPE_COLORFG,SERVICE_INGRESSTYPE_COLORBG,SERVICE_INGRESSTYPE,"INTERCEPTS",NAMEANDRESOLUTION[1]":"ARRAY_CLIENTHOSTS[2])
									PRINTLINE("SUBBRANCH","GREEN","NONE","RESOLVED","ZITI_IP",NAMEANDRESOLUTION[2])
								}
							}

						} else {

							# Match the SERVICE_INADDR.
							split(PRINT_SERVICE[4],ARRAY_CLIENTHOSTS,"=")
							split(ARRAY_CLIENTHOSTS[1],ARRAY_CLIENTHOST," ")
							for (EACH_CLIENTHOST in ARRAY_CLIENTHOST)
								PRINTLINE("BRANCHNORMAL",SERVICE_INGRESSTYPE_COLORFG,SERVICE_INGRESSTYPE_COLORBG,SERVICE_INGRESSTYPE,"INTERCEPTS",ARRAY_CLIENTHOST[EACH_CLIENTHOST]":"ARRAY_CLIENTHOSTS[2])

						}

						# For every SERVICE, loop all CONNECTIONS.
						for (EACH_CONNECTION in CONNECTION_REPORT) {

							# CONNECTIONS # [1]=NUMBER,[2]=SERVICENAME,[3]=CHANNELTERMINATORS
							split(CONNECTION_REPORT[EACH_CONNECTION],PRINT_CONNECTION,",")

							# Match CONNECTION_SERVICENAME to current SERVICE_NAME.
							if (PRINT_SERVICE[3] == PRINT_CONNECTION[2]) {

								PRINTLINE("DOUBLELBR","NONE","NONE"," ","CONNECTION",PRINT_CONNECTION[1]" (TERMINATORS="PRINT_CONNECTION[3]")")

								# For every CONNECTION, loop all CHILDREN.
								for (EACH_CHILD in CHILDREN_REPORT) {

									# CHILDREN # [1]=CHILDCONNECTIONNUMBER,[2]=CHILDNUMBER,[3]=CHILDSTATE,[4]=CHILDCALLERID,[5]=CHILDCHANNELROUTER,[6]=CHILDINFOA,[7]CHILDINFOB
									split(CHILDREN_REPORT[EACH_CHILD],PRINT_CHILD,",")

									# Match CHILD_CONNECTIONNUMBER to current CONNECTION_NUMBER.
									if (PRINT_CHILD[1] == PRINT_CONNECTION[1]) {

										# For every matched CHILD, loop all CHANNELS.
										for (EACH_CHANNEL in CHANNEL_REPORT) {

											# CHANNELS # [1]=NUMBER,[2]=ROUTER,[3]=STATE,[4]=LATENCY
											split(CHANNEL_REPORT[EACH_CHANNEL],PRINT_CHANNEL,",")

											# Add the CHANNEL to the orphan list if its not connected.
											if (PRINT_CHANNEL[3] != "CONNECTED") {
												CHANNEL_ORPHANSEMAPHORE="FALSE"
												for (EACH_ORPHAN in CHANNEL_ORPHANS) {
													# CHANNEL ORPHANS # [1]=NUMBER,[2]=ROUTER,[3]=STATE,[4]=LATENCY
													split(CHANNEL_ORPHANS[EACH_ORPHAN],CHECK_CHANNELORPHAN,",")
													# Match the CHANNELORPHAN_NUMBER to the current CHANNEL_NUMBER.
													if (CHECK_CHANNELORPHAN[1] == PRINT_CHANNEL[1]) {
														CHANNEL_ORPHANSEMAPHORE="TRUE"
														CHANNEL_ORPHANS_PRESENT="1"
														break
													}
												}
												if (CHANNEL_ORPHANSEMAPHORE == "FALSE")
													CHANNEL_ORPHANS[++CHANNEL_ORPHANCOUNTER]=PRINT_CHANNEL[1]","PRINT_CHANNEL[2]","PRINT_CHANNEL[3]","PRINT_CHANNEL[4]
											}

											# Match the CHANNEL_ROUTER to the current CHILD_CHANNELROUTER or if not assigned.
											if (PRINT_CHILD[5] == PRINT_CHANNEL[1] || PRINT_CHILD[5] == "(none)" ) {
												# Emphasize latency if above threshold.
												if (PRINT_CHANNEL[4] < 50) {
													PRINT_CHANNEL[4]="<span class=\"FG-GREEN\">"PRINT_CHANNEL[4]"ms</span>"
												} else if (PRINT_CHANNEL[4] < 100) {
													PRINT_CHANNEL[4]="<span class=\"FG-BLACK BG-YELLOW\">"PRINT_CHANNEL[4]"ms</span>"
												} else {
													PRINT_CHANNEL[4]="<span class=\"FG-WHITE BG-RED\">"PRINT_CHANNEL[4]"ms</span>"
												}

												# Match the CONNECTION_STATE, and print the information.
												split(PRINT_CHANNEL[2],PRINT_CHANNELPARTS,"@")
												if (PRINT_CHILD[3] == "CONNECTED" || PRINT_CHILD[3] == "ACCEPTING") {
													PRINTLINE("BRANCHNORMAL","WHITE","GREEN",PRINT_CHILD[3],"CHILD","#"PRINT_CHILD[2])
												} else if (PRINT_CHILD[3] == "DISCONNECTED" || PRINT_CHILD[3] == "TIMEDOUT") {
													PRINTLINE("BRANCHNORMAL","WHITE","RED",PRINT_CHILD[3],"CHILD","#"PRINT_CHILD[2])
												} else {
													PRINTLINE("BRANCHNORMAL","BLACK","YELLOW",PRINT_CHILD[3],"CHILD","#"PRINT_CHILD[2])
												}
												PRINTLINE("DOUBLELBR","NONE","NONE"," ","CHANNEL",PRINT_CHANNELPARTS[1])
												PRINTLINE("DOUBLELBR","NONE","NONE"," ","AT",PRINT_CHANNELPARTS[2])
												PRINTLINE("DOUBLELBR","NONE","NONE"," ","LATENCY",PRINT_CHANNEL[4])
												PRINTLINE("DOUBLELBR","NONE","NONE"," ","TIMING_DATA",PRINT_CHILD[6])
												PRINTLINE("DOUBLELBR","NONE","NONE"," ","BRIDGE_INFO",PRINT_CHILD[7])
												break

											}

										}

									}

								}

							}

						}

						PRINTLINE("FINAL",SERVICE_EGRESSTYPE_COLORFG,SERVICE_EGRESSTYPE_COLORBG,SERVICE_EGRESSTYPE,"HOSTS",PRINT_SERVICE[5])
					}

					if (CHANNEL_ORPHANCOUNTER > 0) PRINTLINE("SINGLELBR")

					for (EACH_CHANNELORPHAN in CHANNEL_ORPHANS) {

						# CHANNEL ORPHANS # [1]=NUMBER,[2]=ROUTER,[3]=STATE,[4]=LATENCY
						split(CHANNEL_ORPHANS[EACH_CHANNELORPHAN],PRINT_ORPHAN,",")
						split(PRINT_ORPHAN[2],PRINT_ORPHANPARTS,"@")
						PRINTLINE("INITIAL","NONE","NONE",sprintf("%04d",++EACH_CHANNELORPHANCOUNTER),"CHAN_ORPHAN",PRINT_ORPHANPARTS[1])
						PRINTLINE("FINAL","WHITE","RED",PRINT_ORPHAN[3],"FROM",PRINT_ORPHANPARTS[2])

					}

					# Final printing line.
					PRINTLINE("SINGLELBR")
					PRINTLINE("TAIL","GREEN","NONE",sprintf("%02d/%s/%s",ZITICONTEXT_COUNTER,PRINT_ZITICONTEXT[2],PRINT_ZITICONTEXT[1]))

				}

			' "${ZETResults[${i}]}" ||
				printf "<span class=\"FG-WHITE BG-RED\">%s</span></span><br>" "ERROR: Parsing (AWK) failed. Please report this!"

		done

		# Cleanup.
		rm -f "${ZETSocksDir}"/*.ziti 2>/dev/null

	else

		printf "<span class=\"FG-WHITE BG-RED\">%s</span></span><br>" "Could not find the ZET Socket to connect to!"
		return

	fi

	# Final cleanup.
	rm -f "${ZETSocksDir}"/*.ziti 2>/dev/null
	return
}

####################################################################################################
# MAIN
####################################################################################################
printf "<span id=\"ZETDATE-SYSTEM\" class=\"CENTERDATE FULLWIDTH\">SYSTEM DATE : %s</span><hr>" "$(date -u +'%A, %d-%b-%y %H:%M:%S UTC')"
printf "<span id=\"ZETDETAIL\" class=\"FULLWIDTH\">%s</span>" "$(ZET_Status)"