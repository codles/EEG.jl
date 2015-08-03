#
# BIOSEMI
#

fname = joinpath(dirname(@__FILE__), "data", "test_Hz19.5-testing.bdf")

dats, evtTab, trigs, statusChan = readBDF(fname);
sampRate = readBDFHeader(fname)["sampRate"][1]

@test trigs == create_channel(evtTab, dats, sampRate, code="code", index="idx", duration="dur")

@test trigs !== trigger_channel(read_SSR(fname))

@test trigs == trigger_channel(read_SSR(fname, valid_triggers=[-1000:10000]))

s  = read_SSR(fname)
s.header["subjID"] = "test"
write_SSR(s, "testwrite.bdf")
s  = read_SSR(fname, valid_triggers=[-1000:10000])
s.header["subjID"] = "test"
write_SSR(s, "testwrite.bdf")
s2 = read_SSR("testwrite.bdf", valid_triggers=[-1000:10000])

show(s)
show(s2)

@test s.data == s2.data
@test s.triggers == s2.triggers
@test s.samplingrate == s2.samplingrate
@test contains(s2.header["subjID"], "test")


#
# BESA
#

s = read_SSR(  joinpath(dirname(@__FILE__), "data", "test_Hz19.5-testing.bdf"))
s = read_evt(s, joinpath(dirname(@__FILE__), "data", "test.evt"))


#
# Convert between events and channels
#

fname = joinpath(dirname(@__FILE__), "data", "test_Hz19.5-testing.bdf")
dats, evtTab, trigs, statusChan = readBDF(fname);

events  = create_events(trigs, sampRate)
channel = create_channel(events, dats, sampRate)

@test channel == trigs


#
# Test avr files
#

fname = joinpath(dirname(@__FILE__), "data", "test.avr")
sname = joinpath(dirname(@__FILE__), "data", "same.avr")

a, b = read_avr(fname)

write_avr(sname, a, b, 8192)

a2, b2 = read_avr(sname)

@test a==a2
@test b==b2


#
# Test dat files
#

fname = joinpath(dirname(@__FILE__), "data", "test-4d.dat")
sname = joinpath(dirname(@__FILE__), "data", "same.dat")

x, y, z, s, t = read_dat(fname)

@test size(x) == (30,)
@test size(y) == (36,)
@test size(z) == (28,)
@test size(s) == (30,36,28,2)
@test size(t) == (2,)

@test maximum(x) == 72.5
@test maximum(y) == 71.220001
@test maximum(z) == 76.809998
@test maximum(s) == 0.067409396
@test maximum(t) == 0.24

@test minimum(x) == -72.5
@test minimum(y) == -103.779999
@test minimum(z) == -58.189999
@test minimum(s) == 0.0
@test minimum(t) == 0.12

write_dat(sname, x, y, z, s[:,:,:,:], t)

x2, y2, z2, s2, t2 = read_dat(sname)

@test x==x2
@test y==y2
@test z==z2
@test s==s2
@test t==t2


fname = joinpath(dirname(@__FILE__), "data", "test-3d.dat")
x, y, z, s, t = read_dat(fname)

@test size(x) == (30,)
@test size(y) == (36,)
@test size(z) == (28,)
@test size(s) == (30,36,28,1)
@test size(t) == (1,)

@test maximum(x) == 72.5
@test maximum(y) == 71.220001
@test maximum(z) == 76.809998
@test maximum(s) == 33.2692985535
@test maximum(t) == 0

@test minimum(x) == -72.5
@test minimum(y) == -103.779999
@test minimum(z) == -58.189999
@test minimum(s) == -7.5189352036
@test minimum(t) == 0

println()
println("!! Read/Write test passed !!")
println()
