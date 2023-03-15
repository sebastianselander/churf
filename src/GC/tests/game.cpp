#include <vector>

#include "player.hpp"
#include "heap.hpp"

#define X_LENGTH 1000;
#define Y_LENGTH 500;

/*
* Description: 
*   This class is designed to test the Garbage Collector with a mock game,
*   that consists of several live objects in the form of players, that in 
*   turn consists partially of Point objects. 
*
* Goal: 
*   to find out if all the objects are allocated successfully
*   and to see if they are reachable from the stack, i.e. they can get marked. 
* 
* Result: 
*   all objects gets allocated, but only Game object gets marked.
*/

class Game {

private:

    std::vector<Player> players;
    Point dimensions;

public:

    Game() : dimensions(1000, 500) {}

    void add_player(Player& p) {
        players.push_back(p);
    }

    Player* create_player(string s, Point pos, Point size, Point dir) {
        Player *p = static_cast<Player*>(GC::Heap::alloc(sizeof(Player)));
        /* 
        Cannot allocate by new, since it the allocates outside of "out" heap. That also lead so us having to
        define an alternative constructor, that's actually a method. Since our "alloc" does not call the constructor
        of the object
        */
        p->init(s, pos, size, dir);
        return p; 
    }

    void create_players(int nr) {
        for (int i = 0; i < nr; i++) {
            Player *p = create_player(std::to_string(i), Point(i, i), Point(2, 2), Point(0, 0)); 
            add_player(*p);
        }
    }

};


int main() {
    GC::Heap::init();
    GC::Heap *gc = GC::Heap::debug_the();
    gc->check_init();

    Game *game = static_cast<Game*>(gc->alloc(sizeof(Game)));
    game->create_players(2);

    std::cout << "Player size: " << sizeof(Player) << std::endl;
    std::cout << "Game size: " << sizeof(Game) << std::endl;
    std::cout << "Point size: " << sizeof(Point) << std::endl;

    gc->collect(GC::MARK);     
    gc->print_contents();

    return 0;
}