#----------------------	-----C++ Makefile--------------------------------------#
# 
# Features: Handles a multi-directory structure for projects and component-
# specific recompilation for dependencies.
# 
# Type make to compile, make clean to remove executable and object files,
# and make cleaner to remove TDIR, SDIR, and ODIR. Using this make file in an
# empty directory will set up the folders necessary.
# 
# 
# Layout:
#	.		: Put this Makefile in the top level of the project.
#	./src	: Directory for source files (Todo: subdirectories for clases)
#	./dep	: Directory for placing dependency information.
#	./obj	: Directory for object file storage
#	./bin	: Directory for where to place the target executable.
# 
#--- See http://www.gnu.org/software/make/manual/make.html for more info.------#
.SECONDEXPANSION:


# Flags for the compiler.
CC = g++
CPPFLAGS = -g -Wall -std=c++11

# -M: Output rule suitable for make (MM don't include system deps)
# -MT: Set target to specified string
# -MP: Add phony targets for each dependency other than main file
# -MF: Output dependencies to specific location

DEPFLAGS = -MT $@ -MM -MP -MF # when using $(DEPFLAGS), put output info after.
NODEP = clean cleaner

#----- Change the name of the compiled program here. --------------------------#
NAME = qsort

#-- If desired, change these variables to store files in other locations. -----#
SDIR := ./src
LDIR := $(SDIR)/.lnk
DDIR := ./.dep
ODIR := ./.obj
TDIR := .# changed from ./bin -> .

# Grab source files from $(SDIR). Process them for linking.
$(shell if [ ! -d "$(SDIR)/" ]; then mkdir $(SDIR)/; fi)
SRC := $(shell find $(SDIR) -print | grep .cpp | sed 's,\(.*/\)\(.*\)\(\.cpp\),\2\1\2\3,')

# Convert the source file names to object file names.
$(shell if [ ! -d "$(ODIR)/" ]; then mkdir $(ODIR)/; fi)
OBJS := $(addprefix $(ODIR)/, $(notdir $(patsubst %.cpp, %.o, $(SRC))))

# Prepare these if building, but not if cleaning.
ifneq ($(MAKECMDGOALS), $(NODEP))

# Name and location of final executable.
$(shell if [ ! -d "$(TDIR)/" ]; then mkdir $(TDIR)/; fi)
TARGET := $(TDIR)/$(NAME)

# Process source file information to set up links.
$(shell if [ ! -d "$(LDIR)/" ]; then mkdir $(LDIR)/; fi)
LNKPATH := $(shell find $(SDIR) -print | grep .cpp | sed 's,\./.*/\(.*\)\.cpp,$(LDIR)/\1-dir,')
vpath %.cpp $(LNKPATH)

# Extract the name information from source files.
LNK := $(notdir $(patsubst %.cpp, %, $(SRC)))

# Prepare dependency information.
$(shell if [ ! -d "$(DDIR)/" ]; then mkdir $(DDIR)/; fi)
DEPS := $(addprefix $(DDIR)/, $(notdir $(patsubst %.cpp, %.d, $(SRC))))
endif

# Prevent the execution of certain parts the first time MAKE is called.
STEPS = FirstStep SecondStep ThirdStep
TAGS = Tag1 Tag2 Tag3
ifeq ($(MAKELEVEL), 0)
STEP = FirstStep
endif
ifeq ($(MAKELEVEL), 1)
STEP = SecondStep
endif
ifeq ($(MAKELEVEL), 2)
STEP = ThirdStep
endif

#-------------------  Rules for Handling compilation --------------------------#

# General rule.
# First Part of Execution: Get symbolic links to sources.
# Second Part of Execution: Compile and link source code.
all: $(STEP)

# Compile the program.
# $@ gets the target, $^ gets a list of all prequisities.
$(TARGET): $(OBJS)
	$(CC) $(CPPFLAGS) -o $@ $^

# Create symbolic links to source files to avoid problems with whitespaced-filenames.
# sed 's,.*$@\./\(.*/\)$@\.cpp.*,\1,') extracts directory information
$(LNK): % :
	rm -f $$(echo $(LDIR)/$@-dir)
	ln -s $$(echo ../../$$(echo $(SRC) | sed 's,.*$@\./\(.*/\)$@\.cpp.*,\1,')) $$(echo $(LDIR)/$@-dir)

# Compile object files from the source files. Also retrieves dependency info.
# Look up Make Automatic Variables for descriptions of each one.
$(OBJS): $(ODIR)/%.o: %.cpp 
	$(CC) $(DEPFLAGS) '$(DDIR)/$*.d' '$<'
	@echo '' >> '$(DDIR)/$*.d'
	@echo '$<:' >> '$(DDIR)/$*.d'
	$(CC) -c $(CPPFLAGS) '$<' -o '$@'
	
# This line handles recompilation for dependency changes.
ifeq ($(STEP), SecondStep)
-include $(DEPS)
endif

FirstStep: Tag1 $(LNK) 
	$(MAKE)
	
SecondStep: Tag2 $(TARGET)
	$(MAKE)

ThirdStep: Tag3

#-----------------Rules which dp not make files--------------------------------#
.PHONY: clean cleaner 

#-----------------Rules for cleaning up the directory--------------------------#
clean: 
	rm -f $(TARGET) $(OBJS) $(LNKPATH)
	
cleaner:
	rm -r $(ODIR) $(DDIR) $(LDIR)
	rm -f $(TARGET)
	
#-------------------- Progress Information-------------------------------------#

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
	@echo . \*\*\*\*            FINISHED               \*\*\*\* .
	@echo -----------------------------------------------
	@echo
#------------------------------------------------------------------------------#
