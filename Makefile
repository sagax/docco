
# ** TOOLS **

# 'cake' is not 'cake' on Ubuntu but 'cake.coffeescript'.
# Anyhow, we are now using a local (modern!) install of Cake, so the problem is moot.
#CAKE=cake.coffeescript
CAKE=node_modules/.bin/cake
COFFEE=node_modules/.bin/coffee
# linear | parallel | pretty | plain-markdown | classic
TEMPLATE=parallel



# ** COMMON DEPENDENCIES **

SRC_DEPS=                                       \
		Makefile                                \
		Cakefile                                \
		package.json                            \
		docco.litcoffee

TOOL_DEPS=                                      \
		$(CAKE)                                 \
		$(COFFEE)



# ** MAIN BUILD TARGETS **

.PHONY: all install build doc loc clean

all: build doc loc

install: build doc loc
	$(CAKE) install

build: docco.js

doc: index.html

loc: $(SRC_DEPS) $(TOOL_DEPS)
	$(CAKE) loc

clean:
	-rm index.html
	-rm docco.js

superclean: clean
	-rm -rf node_modules



# ** ASSISTANT/SUBSERVIENT BUILD TARGETS **

docco.js: $(SRC_DEPS) $(TOOL_DEPS)
	$(COFFEE) -c docco.litcoffee
	#$(CAKE) build

index.html: $(SRC_DEPS) $(TOOL_DEPS)
	bin/docco --layout $(TEMPLATE) docco.litcoffee
	sed -e 's/docco.css/resources\/$(TEMPLATE)\/docco.css/g' < docs/docco.litcoffee.html > index.html
	rm -rf docs
	#$(CAKE) doc

# did 'npm install' run before?
$(TOOL_DEPS):
	@echo "*** Installing NodeJS / Cake dependencies for Docco ***"
	npm install

