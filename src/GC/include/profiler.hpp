#pragma once

#include <vector>

#include "chunk.hpp"
#include "event.hpp"

namespace GC {

    class Profiler {
    private:
        Profiler() {}
        ~Profiler()
        {
            for (GCEvent *c : m_events)
                delete c;
        }

        static Profiler *the()
        {
            if (m_instance)
                return m_instance;
            m_instance = new Profiler();
            return m_instance;
        }

        inline static Profiler *m_instance {nullptr};
        std::vector<GCEvent *> m_events;

        std::ofstream create_file_stream();
        std::string get_log_folder();
        static void dump_trace();

    public:
        static void record(GCEventType type);
        static void record(GCEventType type, size_t size);
        static void record(GCEventType type, Chunk *chunk);
        static void dispose();
    };
}