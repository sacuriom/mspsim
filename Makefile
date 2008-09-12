###############################################################
# Makefile for mspsim
#
# Needed stuff in the PATH:
#  java, javac (JDK 1.5 or newer)
#
# Under MS-DOS/Windows
#  A GNU compatible Make (for example Cygwin's)
###############################################################

###############################################################
# Settings
###############################################################
CC=javac
JAVA=java
JAVACC=javacc
JAR=jar
RM=rm -f
CP=cp

###############################################################
# System dependent
###############################################################

ifndef WINDIR
  ifdef OS
    ifneq (,$(findstring Windows,$(OS)))
      WINDIR := Windows
    endif
  endif
endif

ifndef WINDIR
  # This settings are for UNIX
  SEPARATOR=:
  # Add "'" around filenames when removing them because UNIX expands "$"
  APO='#'  (last apostrophe to avoid incorrect font-lock)
else
  # These setting are for Windows
  SEPARATOR=;
  APO=
endif


###############################################################
# Arguments
###############################################################

CLASSPATH=.$(SEPARATOR)lib/jfreechart-1.0.9.jar$(SEPARATOR)lib/jcommon-1.0.12.jar
CCARGS=-deprecation -classpath "${CLASSPATH}"

JAVAARGS=-classpath "${CLASSPATH}"


###############################################################
# SERVER OBJECTS
###############################################################

ifndef FIRMWAREFILE
ESBFIRMWARE = firmware/esb/sensor-demo.firmware
SKYFIRMWARE = firmware/sky/blink.firmware
else
ESBFIRMWARE = ${FIRMWAREFILE}
SKYFIRMWARE = ${FIRMWAREFILE}
endif

CPUTEST := tests/cputest.firmware

BINARY := README.txt license.txt CHANGE_LOG.txt images/*.jpg firmware/*/*.firmware

PACKAGES := ${addprefix se/sics/mspsim/,core platform platform/esb platform/sky cli ui util chip extutil/highlight extutil/jfreechart}

SOURCES := ${wildcard *.java $(addsuffix /*.java,$(PACKAGES))}

OBJECTS := $(SOURCES:.java=.class)

JARFILE := mspsim.jar

###############################################################
# MAKE
###############################################################

.PHONY: all compile jar help run runesb runsky test cputest $(CPUTEST) mtest

all:	compile

compile:	$(OBJECTS)

jar:	clean compile JarManifest.txt
	$(JAR) cfm $(JARFILE) JarManifest.txt ${addsuffix /*.class,$(PACKAGES)} images/*.jpg
	-$(RM) JarManifest.txt

JarManifest.txt:
	@echo >>$@ "Manifest-Version: 1.0"
	@echo >>$@ "Sealed: true"
	@echo >>$@ "Main-Class: se.sics.mspsim.platform.sky.SkyNode"
	@echo >>$@ "Class-path: lib/jfreechart-1.0.9.jar lib/jcommon-1.0.12.jar"

help:
	@echo "Usage: make [all,compile,clean,run,runsky,runesb]"

run:	compile
	$(JAVA) $(JAVAARGS) se.sics.mspsim.util.IHexReader $(ARGS) $(FIRMWAREFILE) $(MAPFILE)

runesb:	compile
	$(JAVA) $(JAVAARGS) se.sics.mspsim.platform.esb.ESBNode $(ARGS) $(ESBFIRMWARE) $(MAPFILE)

runsky:	compile
	$(JAVA) $(JAVAARGS) se.sics.mspsim.platform.sky.SkyNode $(ARGS) $(SKYFIRMWARE) $(MAPFILE)

runtelos:	compile
	$(JAVA) $(JAVAARGS) se.sics.mspsim.platform.sky.TelosNode $(ARGS) $(SKYFIRMWARE) $(MAPFILE)


test:	cputest

cputest:	$(CPUTEST)
	$(JAVA) $(JAVAARGS) se.sics.mspsim.util.Test $(CPUTEST)

$(CPUTEST):
	(cd tests && $(MAKE))

mtest:	compile $(CPUTEST)
	@-$(RM) mini-test_cpu.txt
	$(JAVA) $(JAVAARGS) se.sics.util.Test -debug $(CPUTEST) >mini-test_cpu.txt


###############################################################
# ARCHIVE GENERATION
###############################################################

source:
	zip -9 mspsim-source-`date '+%F'`.zip Makefile $(BINARY) *.java $(addsuffix /*.java,$(PACKAGES)) tests/Makefile tests/*.c tests/*.h lib/*.*


###############################################################
# CLASS COMPILATION
###############################################################

%.class : %.java
	$(CC) $(CCARGS) $<


###############################################################
# CLEAN  (untrusted, use with great care!!!)
###############################################################

.PHONY:	clean

clean:
ifdef WINDIR
	-$(RM) *.class ${addsuffix /*.class,$(PACKAGES)}
else
	-$(RM) $(foreach f,$(wildcard *.class),$(APO)$(f)$(APO)) $(foreach dir,$(PACKAGES),$(dir)/*.class)
endif
