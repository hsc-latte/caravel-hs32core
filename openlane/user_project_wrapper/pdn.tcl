# Power nets
set ::power_nets $::env(_VDD_NET_NAME)
set ::ground_nets $::env(_GND_NET_NAME)

pdngen::specify_grid stdcell {
    name grid
	core_ring {
		met5 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_H_OFFSET)}
		met4 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_V_OFFSET)}
	}
	rails {
	}
    straps {
	    met4 {width $::env(_WIDTH) pitch $::env(_V_PITCH) offset $::env(_V_PDN_OFFSET)}
	    met5 {width $::env(_WIDTH) pitch $::env(_H_PITCH) offset $::env(_H_PDN_OFFSET)}
    }
    connect {{met4 met5}}
}

pdngen::specify_grid macro {
	instance "obs_core_obs"
    power_pins $::env(_VDD_NET_NAME)
    ground_pins $::env(_GND_NET_NAME)
    blockages "li1 met1 met2 met3 met4 met5"
    straps { 
    } 
    connect {}
}

# Prevent shorting across all power domains
if { $::env(CONNECT_GRIDS) } {
    pdngen::specify_grid macro {
        power_pins "VPWR"
        ground_pins "VGND"
        blockages "li1 met1 met2 met3 met4"
        straps {
        }
        connect { { met4_PIN_ver met5 } }
    }
    pdngen::specify_grid macro {
        macro "sram_1rw1r_32_256_8_sky130"
        power_pins "vdd"
        ground_pins "gnd"
        blockages "li1 met1 met2 met3 met4"
        straps {
        }
        connect { { met4_PIN_ver met5 } }
    }
} else {
    pdngen::specify_grid macro {
        power_pins "VPWR"
        ground_pins "VGND"
        blockages "li1 met1 met2 met3 met4"
        straps { }
        connect { }
    }
    pdngen::specify_grid macro {
        macro "sram_1rw1r_32_256_8_sky130"
        power_pins "vdd"
        ground_pins "gnd"
        blockages "li1 met1 met2 met3 met4"
        straps { }
        connect { }
    }
}

set ::halo 15

# POWER or GROUND #Std. cell rails starting with power or ground rails at the bottom of the core area
set ::rails_start_with "POWER" ;

# POWER or GROUND #Upper metal stripes starting with power or ground rails at the left/bottom of the core area
set ::stripes_start_with "POWER" ;
