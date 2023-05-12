#!/usr/bin/with-contenv bashio
####################################################################################################
# 20230428 - Written by Nic Fragale @ NetFoundry.
MyName="zetdisplay.sh"
MyPurpose="NetFoundry ZITI Edge Tunnel Runtime Display."
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
			printf "<span class=\"FG-BLACK BG-YELLOW\">%s</span></span><br>" "The ZITI EDGE TUNNEL socket is not available. Please wait or restart."
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
						CONNECTION_REPORT[++CONNECTION_COUNTER]=CONNECTION_NUMBER","CONNECTION_SERVICENAME","CONNECTION_CHANNELROUTER","toupper(CONNECTION_STATE)
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
					CONNECTION_ORPHANCOUNTER=0
					CHANNEL_ORPHANCOUNTER=0
					EACH_CONNECTIONORPHANCOUNTER=0
					delete CONNECTION_ORPHANS[0]
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

					} else if (/\[host.v1\]/) {

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

						SERVICE_SERVERFULLHOST=SERVICE_SERVERHOST":["SERVICE_SERVERPORT"]/["SERVICE_SERVERPROTOCOL"] (FWDPORT="SERVICE_SERVERFORWARDPORT") (FWDPROTO="SERVICE_SERVERFORWARDPROTOCOL")"
						gsub(/,/," ",SERVICE_SERVERFULLHOST)
						gsub(/\"/,"",SERVICE_SERVERFULLHOST)

					} else if (/\[intercept.v1\]/) {

						SERVICE_CLIENTHOST=gensub(/.*\"addresses\":\[([^\]]+)\].*/,"\\1","1")
						split(SERVICE_CLIENTHOST,ARRAY_CLIENTHOSTS,",")
						for (EACH_CLIENTHOST in ARRAY_CLIENTHOSTS) {
							gsub(/\"/,"",ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]) # Remove double quotes.
							FINALRESOLVE=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]
							gsub(/\*\.?/,"",FINALRESOLVE) # Remove star domains.
							if (SERVICE_TYPE == "DIALONLY" || SERVICE_TYPE == "DIALBIND") {
								if (match(ARRAY_CLIENTHOSTS[EACH_CLIENTHOST],/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"@IPONLY"
								} else {
									RUNCOMMAND = "echo -n TRYDNS:$(dig +short "FINALRESOLVE" 2>&1)"
									RUNCOMMAND | getline EACH_CLIENTHOSTRESOLVED
									close(RUNCOMMAND)
									gsub(/ /,"|",EACH_CLIENTHOSTRESOLVED)
									ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]"@"EACH_CLIENTHOSTRESOLVED
								}
							} else {
								ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]=ARRAY_CLIENTHOSTS[EACH_CLIENTHOST]
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

						CONNECTION_NUMBER=gensub(/^(conn\[.*\]): .*/,"\\1","1")
						CONNECTION_SERVICENAME=gensub(/.*service\[(.*)\] using.*/,"\\1","1")
						CONNECTION_CHANNELROUTER=gensub(/.*ch\[.*\] (.*)/,"\\1","1")
						CONNECTION_STATE=gensub(/.*state\[(.*)\] service.*/,"\\1","1")
						READYSAVE("CONNECTIONS")

					# CONNECTIONS/CHILDREN SUBSECTION #
					} else if (/child\[.*\]/) {

						CONNECTION_CHILDTOCONNECTIONNUMBER=CONNECTION_NUMBER
						CONNECTION_CHILDNUMBER=gensub(/^(conn\[.*\]): .*/,"\\1","1")
						CONNECTION_CHILDSTATE=gensub(/.*state\[(.*)\] service.*/,"\\1","1")
						CONNECTION_CHILDCALLERID=gensub(/.*caller_id\[(.*)\]/,"\\1","1")

					# CHANNELS SECTION #
					} else if (/ch\[.*\]/) {

						CHANNEL_NUMBER=gensub(/^(ch\[.*\])\(.*/,"\\1","1")
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
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┏</span><span class=\"FG-GREEN\">%02d/%s/%s</span></span><br>",ZITICONTEXT_COUNTER,PRINT_ZITICONTEXT[2],PRINT_ZITICONTEXT[1]
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃</span></span><br>"
					}

					# Combine the SERVICE arrays in proper order and sorting.
					CONCATARRAY(SERVICE_DIALREPORT,SERVICE_BINDREPORT,SERVICE_REPORT)
					# Loop all SERVICES.
					for (EACH_SERVICE = 1; EACH_SERVICE <= ARRAY_GLOBALCOUNTER; EACH_SERVICE++) {

						if ((CHANNEL_ORPHANS_PRESENT) || (CONNECTION_ORPHANS_PRESENT) || (EACH_SERVICE != ARRAY_GLOBALCOUNTER)) {
							BRCHAR[1]="┣┳"
							BRCHAR[2]="┃"
						} else {
							BRCHAR[1]="┣┳"
							BRCHAR[2]="┃"
						}

						# SERVICES # [1]=ID,[2]=TYPE,[3]=NAME,[4]=INADDR@RESOLVED,[5]=OUTADDR
						split(SERVICE_REPORT[EACH_SERVICE],PRINT_SERVICE,",")

						# If the user passed in a filter, and that filter is not matched here, continue past this service.
						if (FILTER) {
							SERVICELINE=EACH_SERVICE"/"PRINT_SERVICE[2]"/"PRINT_SERVICE[1]"/"PRINT_SERVICE[3]
							if (SERVICELINE !~ FILTER) continue
						}

						# First output line with service information.
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┣┳</span><span>%04d/%s/%s/%s</span></span><br>",EACH_SERVICE,PRINT_SERVICE[2],PRINT_SERVICE[1],PRINT_SERVICE[3]

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
							SERVICE_INGRESSTYPE="<span class=\"FG-WHITE BG-BLUE\">INGRESS&nbsp;&nbsp;</span>"
							SERVICE_EGRESSTYPE="<span class=\"FG-GREY\">EGRESS&nbsp;&nbsp;&nbsp;</span>"
						} else if (PRINT_SERVICE[2] == "DIALBIND") {
							SERVICE_INGRESSTYPE="<span class=\"FG-WHITE BG-BLUE\">INGRESS&nbsp;&nbsp;</span>"
							SERVICE_EGRESSTYPE="<span class=\"FG-WHITE BG-BLUE\">EGRESS&nbsp;&nbsp;&nbsp;</span>"
						} else if (PRINT_SERVICE[2] == "BINDONLY") {
							SERVICE_INGRESSTYPE="<span class=\"FG-GREY\">INGRESS&nbsp;&nbsp;</span>"
							SERVICE_EGRESSTYPE="<span class=\"FG-WHITE BG-BLUE\">EGRESS&nbsp;&nbsp;&nbsp;</span>"
						}

						# Match the SERVICE_TYPE.
						if (PRINT_SERVICE[2] == "DIALONLY" || PRINT_SERVICE[2] == "DIALBIND") {

							if (NETSESSION_FOUNDSEMAPHORE == "TRUE") {
								printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣━</span><span class=\"FG-GREEN\">%s</span><span>%s</span></span><br>","SESSAUTH&nbsp;&nbsp;","Authorization Token = "PRINT_NETSESSION[1]""
							} else {
								printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣━</span><span class=\"FG-RED\">%s</span><span>%s</span></span><br>","SESSAUTH&nbsp;&nbsp;","Authorization Token NOT PRESENT"
							}

							# Match the SERVICE_INADDR@RESOLVED.
							split(PRINT_SERVICE[4],ARRAY_CLIENTHOSTS,"=")
							split(ARRAY_CLIENTHOSTS[1],ARRAY_CLIENTHOSTRESOLUTIONS," ")
							for (EACH_CLIENTHOSTRESOLUTION in ARRAY_CLIENTHOSTRESOLUTIONS) {
								split(ARRAY_CLIENTHOSTRESOLUTIONS[EACH_CLIENTHOSTRESOLUTION],NAMEANDRESOLUTION,"@")
								if (NAMEANDRESOLUTION[2] == "TRYDNS:") {
									printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣┳</span><span>%s %s:%s</span></span><br>",SERVICE_INGRESSTYPE,NAMEANDRESOLUTION[1],ARRAY_CLIENTHOSTS[2]
									printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┃┗━</span><span class=\"FG-RED\">%s </span><span>%s</span></span><br>","ZITIDNS&nbsp;","NO RESOLUTION"
								} else if (NAMEANDRESOLUTION[2] == "IPONLY") {
									printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣━</span><span>%s %s:%s</span></span><br>",SERVICE_INGRESSTYPE,NAMEANDRESOLUTION[1],ARRAY_CLIENTHOSTS[2]
								} else {
									gsub(/TRYDNS:/,"",NAMEANDRESOLUTION[2])
									printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣┳</span><span>%s %s:%s</span></span><br>",SERVICE_INGRESSTYPE,NAMEANDRESOLUTION[1],ARRAY_CLIENTHOSTS[2]
									printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┃┗━</span><span class=\"FG-BLUE\">%s </span><span>%s</span></span><br>","ZITIDNS&nbsp;",NAMEANDRESOLUTION[2]
								}
							}

						} else {

							# Match the SERVICE_INADDR.
							split(PRINT_SERVICE[4],ARRAY_CLIENTHOSTS,"=")
							split(ARRAY_CLIENTHOSTS[1],ARRAY_CLIENTHOST," ")
							for (EACH_CLIENTHOST in ARRAY_CLIENTHOST)
								printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣━</span><span>%s %s:%s</span></span><br>",SERVICE_INGRESSTYPE,ARRAY_CLIENTHOST[EACH_CLIENTHOST],ARRAY_CLIENTHOSTS[2]

						}

						# For every SERVICE, loop all CONNECTIONS.
						for (EACH_CONNECTION in CONNECTION_REPORT) {

							# CONNECTIONS # [1]=NUMBER,[2]=SERVICENAME,[3]=CHANNELROUTER,[4]=STATE
							split(CONNECTION_REPORT[EACH_CONNECTION],PRINT_CONNECTION,",")
							# Match CONNECTION_SERVICENAME to current SERVICE_NAME.
							if (PRINT_SERVICE[3] == PRINT_CONNECTION[2]) {

								# For every CONNECTION, loop all CHANNELS.
								for (EACH_CHANNEL in CHANNEL_REPORT) {

									# CHANNELS # [1]=NUMBER,[2]=ROUTER,[3]=STATE,[4]=LATENCY
									split(CHANNEL_REPORT[EACH_CHANNEL],PRINT_CHANNEL,",")

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

									# Match the CHANNEL_ROUTER to the current CONNECTION_CHANNELROUTER or if not assigned.
									if (PRINT_CONNECTION[3] == PRINT_CHANNEL[2] || PRINT_CONNECTION[3] == "(none)" ) {

										# Match the CHANNEL_STATE.
										if (PRINT_CHANNEL[3] == "CONNECTED") {
											PRINT_CHANNEL[3]="<span class=\"FG-GREEN\">"PRINT_CHANNEL[3]"&nbsp;</span>"
										} else {
											PRINT_CHANNEL[3]="<span class=\"FG-RED\">"PRINT_CHANNEL[3]"&nbsp;&nbsp;&nbsp;&nbsp;</span>"
										}

										# Emphasize latency if above threshold.
										if (PRINT_CHANNEL[4] < 50) {
											PRINT_CHANNEL[4]="<span class=\"FG-GREEN\">"PRINT_CHANNEL[4]"</span>"
										} else if (PRINT_CHANNEL[4] < 100) {
											PRINT_CHANNEL[4]="<span class=\"FG-YELLOW\">"PRINT_CHANNEL[4]"</span>"
										} else {
											PRINT_CHANNEL[4]="<span class=\"FG-RED\">"PRINT_CHANNEL[4]"</span>"
										}

										# Match the CONNECTION_STATE, and print the information.
										printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┣━</span>"
										if (PRINT_CONNECTION[4] == "BOUND") {
											printf "<span class=\"FG-WHITE BG-GREEN\">%s </span>",PRINT_CONNECTION[4]"&nbsp;&nbsp;&nbsp;&nbsp;"
										} else if (PRINT_CONNECTION[4] == "CONNECTED") {
											printf "<span class=\"FG-WHITE BG-GREEN\">%s </span>",PRINT_CONNECTION[4]
										} else {
											printf "<span class=\"FG-BLACK BG-YELLOW\">%s </span>",PRINT_CONNECTION[4]
										}
										# Ascertain the name and URL parts of the PRINT_CHANNEL.
										split(PRINT_CHANNEL[2],PRINT_CHANNELPARTS,"@")
										printf "<span class=\"FG-ITALIC\"> to </span><span>%s</span></span><br>",PRINT_CHANNELPARTS[1]
										printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┃&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>"
										printf "<span class=\"FG-ITALIC\"> at </span><span>%s</span></span><br>",PRINT_CHANNELPARTS[2]
										printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┃&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>"
										printf "<span class=\"FG-ITALIC\"> with latency </span><span>%s</span></span><br>",PRINT_CHANNEL[4]

										break

									}

								}

							break

							} else if (PRINT_CONNECTION[4] != "BOUND" && PRINT_CONNECTION[4] != "CONNECTED" && PRINT_CONNECTION[4] != "CONNECTING") {

								CONNECTION_ORPHANSEMAPHORE="FALSE"
								for (EACH_ORPHAN in CONNECTION_ORPHANS) {
									# CONNECTION ORPHANS # [1]=NUMBER,[2]=SERVICENAME,[3]=CHANNELROUTER,[4]=STATE
									split(CONNECTION_ORPHANS[EACH_ORPHAN],CHECK_CONNECTIONORPHAN,",")
									# Match the CONNECTIONORPHAN_NUMBER to the current CONNECTION_NUMBER -OR- if CONNECTION_CHANNELROUTER is NULL/NONE.
									if (CHECK_CONNECTIONORPHAN[1] == PRINT_CONNECTION[1] || PRINT_CONNECTION[3] == "(null)" || PRINT_CONNECTION[3] == "(none)") {
										CONNECTION_ORPHANSEMAPHORE="TRUE"
										CONNECTION_ORPHANS_PRESENT="1"
									}
								}
								if (CONNECTION_ORPHANSEMAPHORE == "FALSE")
									CONNECTION_ORPHANS[++CONNECTION_ORPHANCOUNTER]=PRINT_CONNECTION[1]","PRINT_CONNECTION[2]","PRINT_CONNECTION[3]","PRINT_CONNECTION[4]

							}

						}
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┗━</span><span>%s %s</span></span><br>",SERVICE_EGRESSTYPE,PRINT_SERVICE[5]

					}

					for (EACH_CHANNELORPHAN in CHANNEL_ORPHANS) {

						# CHANNEL ORPHANS # [1]=NUMBER,[2]=ROUTER,[3]=STATE,[4]=LATENCY
						split(CHANNEL_ORPHANS[EACH_CHANNELORPHAN],PRINT_ORPHAN,",")
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃</span></span><br>"
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┣┳</span><span>%04d/CHANNEL_ORPHAN/%s</span></span><br>",++EACH_CHANNELORPHANCOUNTER,PRINT_ORPHAN[1]
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┗━</span><span class=\"FG-WHITE BG-RED\">%s</span><span>Channel \"%s\" is not in a proper state to handle a service.</span></span><br>",PRINT_ORPHAN[3],PRINT_ORPHAN[2]

					}

					for (EACH_CONNECTIONORPHAN in CONNECTION_ORPHANS) {

						# CONNECTION ORPHANS # [1]=NUMBER,[2]=SERVICENAME,[3]=CHANNELROUTER,[4]=STATE
						split(CONNECTION_ORPHANS[EACH_CONNECTIONORPHAN],PRINT_ORPHAN,",")
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃</span></span><br>"
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┣┳</span><span>%04d/CONNECTION_ORPHAN/%s</span></span><br>",++EACH_CONNECTIONORPHANCOUNTER,PRINT_ORPHAN[1]
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃┗━</span><span class=\"FG-WHITE BG-RED\">%s</span><span> Linking is broken between channel \"%s\" and service \"%s\".</span></span><br>",PRINT_ORPHAN[4],PRINT_ORPHAN[3],PRINT_ORPHAN[2]

					}

					# Final printing line.
					if (ZITICONTEXT_COUNTER == ZITICONTEXT_COUNTEREND) {
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃</span></span><br>"
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┗</span><span class=\"FG-GREEN\">%02d/%-9s/%s</span></span><br>",ZITICONTEXT_COUNTER,PRINT_ZITICONTEXT[2],PRINT_ZITICONTEXT[1]
					} else {
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┃</span></span><br>"
						printf "<span class=\"ZETDETAILLINE FULLWIDTH\"><span class=\"FG-GREEN\">┗</span><span class=\"FG-GREEN\">%02d/%-9s/%s</span><br><br>",ZITICONTEXT_COUNTER,PRINT_ZITICONTEXT[2],PRINT_ZITICONTEXT[1]
					}

				}
			' "${ZETResults[${i}]}" 2>/dev/null ||
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
printf "<span id=\"ZETDATE-SYSTEM\" class=\"CENTERDATE FULLWIDTH\">%s: %s</span><hr>" "SYSTEM DATE " "$(date -u +'%A, %d-%b-%y %H:%M:%S UTC')"
printf "<span id=\"ZETDETAIL\" class=\"FULLWIDTH\">%s</span>" "$(ZET_Status)"
