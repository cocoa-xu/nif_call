PRIV_DIR = $(MIX_APP_PATH)/priv
BUILD_DIR = $(MIX_APP_PATH)/build
NIF_SO = $(PRIV_DIR)/nif.so

CFLAGS = -fPIC -I$(ERTS_INCLUDE_DIR) -Wall -std=c++17 -O3
LDFLAGS = -shared

UNAME_S = $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
    LDFLAGS += -flat_namespace -undefined dynamic_lookup
endif

SOURCES = c_src/nif_call.c
OBJECTS = $(patsubst c_src/%.c,$(BUILD_DIR)/%.o,$(SOURCES))

all: $(NIF_SO)

$(PRIV_DIR):
	@ mkdir -p $(PRIV_DIR)

$(BUILD_DIR):
	@ mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: c_src/%.cpp
	$(CXX) $(CFLAGS) -c $< -o $@

$(NIF_SO): $(PRIV_DIR) $(BUILD_DIR) $(OBJECTS)
	$(CXX) $(OBJECTS) -o $(NIF_SO) $(LDFLAGS)

clean:
	@rm -rf $(PRIV_DIR)
	@rm -rf $(BUILD_DIR)

.PHONY: all clean
