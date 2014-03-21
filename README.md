# Neuroevolution In Elixir

I'm currently reading [Handbook of Neuroevolution Through Erlang][book] and
learning a lot.  In it are examples showing how to build neural nets with
Erlang.  In order to drive home what I'm learning and to learn the Elixir
syntax I'm translating the Erlang code to Elixir as I go.

[book]: http://www.amazon.com/Handbook-Neuroevolution-Through-Erlang-Gene/dp/1461444624


## Simple Neuron

    mix -S iex
    SimpleNeuron.create
    SimpleNeuron.sense [1,2]

