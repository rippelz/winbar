CXX      ?= g++
SRC       = minimize.cpp
OUT       = $(HOME)/.local/lib/hypr-minimize.so

CXXFLAGS += -shared -fPIC -std=c++23 -O2 -Wall
CXXFLAGS += $(shell pkg-config --cflags hyprland pixman-1 libdrm hyprutils)
LDFLAGS  += $(shell pkg-config --libs hyprutils)

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC)
	mkdir -p $(dir $(OUT))
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(OUT)
