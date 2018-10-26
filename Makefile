#---------------------------C++ Makefile--------------------------------------#
# 
# Features: Handles a multi-directory structure for projects and automatic
# component-specific compilation for dependencies. It also uses an iterated 
# version of recursive make to build components in order. In addition, if
# needed source files are outside of the project directory, they can be drawn from
# also.
# 
# Type make to compile, make clean to remove executable and object files,
# and make cleaner to remove TARGET, DDIR, LDIR, and ODIR. Using this make file 
# in an empty directory will initialize the folder hierarchy.
# 
# Todo: Make compatible with .c files.
# 
# Layout:
#	.		: Put this Makefile in the top level of the project.
#	./src	: Directory for source files. Allows for subdirectories.
#	./dep	: Directory for placing dependency information.
#	./obj	: Directory for object file storage
#	./bin	: Directory for where to place the target executable.
# 
#    See http://www.gnu.org/software/make/manual/make.html for more info.      #

####################        CHANGEABLE ITEMS     ###############################

#------------------  Output File and Folder Hierarchy -------------------------#

# Change the name of the compiled program here.
NAME = qsort

# If desired, change these variables to store files in other locations.
TDIR = .
SDIR = ./src
ODIR = ./.obj
LDIR = $(ODIR)/.lnk
DDIR = $(ODIR)/.dep

sp =\ 

# Use this variable to locate external source files.
# Make sure that every file pulled into the project is unique. If the source file has
# spaces in the path, use $(sp) or type '\ ' to escape.
# Note that recursive searching of directories is not applied to EXTDIRS.
EXTDIRS = # ex. ./myproject/code/ etc

####################     DON'T CHANGE BELOW HERE     ###########################

#-------------------  Variable Defintions -------------------------------------#

# Flags for the compiler.
CC = g++
CPPFLAGS = -g -Wall -std=c++11

# -M: Output rule suitable for make (MM don't include system deps)
# -MT: Set target to specified string
# -MP: Add phony targets for each dependency other than main file
# -MF: Output dependencies to specific location

DEPFLAGS = -MT $@ -MM -MP -MF # when using $(DEPFLAGS), put output info after.
NODEP = clean cleaner

# This is an escape for spaces.
sp =\\\ 

# Name and location of final executable.
$(shell if [ ! -d "$(TDIR)/" ]; then mkdir $(TDIR)/; fi)
TARGET := $(TDIR)/$(NAME)

# Grab source files from $(SDIR). Look through ./src and directories named in $(EXTDIRS)
$(shell if [ ! -d "$(SDIR)/" ]; then mkdir $(SDIR)/; fi)
SDIR := $(shell find $(SDIR) -type d -print | sed 's, ,\ ,' | sed 's,\(.*\),"\1",')
SDIR += $(EXTDIRS)
SRC := $(shell find $(SDIR) -maxdepth 1 -name '*.cpp' -print | sed 's,.*/\(.*\)\.cpp,\1,')

# Process source file information to set up links.
$(shell if [ ! -d "$(LDIR)/" ]; then mkdir $(LDIR)/; fi)
LNKPATH := $(shell find $(SDIR) -maxdepth 1 -name '*.cpp' -print | sed 's,\./.*/\(.*\)\.cpp, $(LDIR)/\1-dir,')
vpath %.cpp $(LNKPATH)

# Convert the source file names to object file names.
$(shell if [ ! -d "$(ODIR)/" ]; then mkdir $(ODIR)/; fi)
OBJS := $(foreach file, $(SRC), $(ODIR)/$(file).o)

# Prepare dependency information.
$(shell if [ ! -d "$(DDIR)/" ]; then mkdir $(DDIR)/; fi)
DEPS := $(DDIR)/$(notdir $(patsubst %.o, %.d, $(OBJS)))

# Prevent the execution of certain parts each time MAKE is called.
STEPS = ZerothStep FirstStep SecondStep ThirdStep
TAGS = Tag0 Tag1 Tag2 Tag3
ifeq ($(MAKELEVEL), 0)
STEP = ZerothStep
endif
ifeq ($(MAKELEVEL), 1)
STEP = FirstStep
endif
ifeq ($(MAKELEVEL), 2)
STEP = SecondStep
endif
ifeq ($(MAKELEVEL), 3)
STEP = ThirdStep
endif

#-------------------  Rules for Handling compilation --------------------------#

# General rule. Switches execution based on each step.
all: $(STEP)

# Compile the program.
$(TARGET): $(OBJS)
	$(CC) $(CPPFLAGS) -o $@ $^

# Create symbolic links to source files.
$(SRC): % :
	rm -f $$(echo $(LDIR)/$@-dir)
	ln -s ../../$(shell find $(SDIR) -maxdepth 1 -name '$*.cpp' -print | \
		sed 's,.*\./\(.*\)/$*.*,\1,g' | \
		sed 's, ,$(sp),g') \
		$(shell echo $(LDIR)/$@-dir)

# Compile object files from the source files. Also retrieves dependency info.
$(OBJS): $(ODIR)/%.o: %.cpp 
	$(CC) $(DEPFLAGS) '$(DDIR)/$*.d' '$<'
	@echo '' >> '$(DDIR)/$*.d'
	@echo '$<:' >> '$(DDIR)/$*.d'
	$(CC) -c $(CPPFLAGS) '$<' -o '$@'
	
# This line handles recompilation for dependency changes.
ifeq ($(STEP), SecondStep)
ifneq ($(MAKECMDGOALS), $(NODEP))
-include $(DEPS)
endif
endif

ZerothStep: Tag0
	($(MAKE))

FirstStep: Tag1 $(SRC) 
	($(MAKE))
	
SecondStep: Tag2 $(TARGET)
	($(MAKE))

ThirdStep: Tag3

#-------------------- Progress Information-------------------------------------#

Tag0:
	@echo  
	@echo -----------------------------------------------
	@echo . \*\*\*\* Preparing $(NAME) For Build \*\*\*\* .
	@echo -----------------------------------------------
	@echo  
	@echo Source directories: '$(SDIR)'

Tag1:
	@echo  
	@echo -----------------------------------------------
	@echo . \*\*\*\* Getting Symbolic Links to Sources \*\*\*\* .
	@echo -----------------------------------------------
	@echo 

Tag2:
	@echo 
	@echo -----------------------------------------------
	@echo . \*\*\*\* Compiling and Linking Source Code \*\*\*\* .
	@echo -----------------------------------------------
	@echo 

Tag3:
	@echo 
	@echo -----------------------------------------------
	@echo . \*\*\*\* FINISHED \*\*\*\* .
	@echo -----------------------------------------------
	@echo

#-----------------Rules which do not make files--------------------------------#

.PHONY: clean cleaner $(STEPS) $(TAGS)

#-----------------Rules for cleaning up the directory--------------------------#

clean: 
	rm -f $(TARGET) $(OBJS) $(LNKPATH)
	
cleaner:
	rm -r $(ODIR)
	rm -f $(TARGET)
	
#------------------------------------------------------------------------------#
