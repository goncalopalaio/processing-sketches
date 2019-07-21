class IVec2 {
  int x;
  int y;
  IVec2(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

class IVec3 {
  int x;
  int y;
  int z;
  IVec3(int x, int y, int z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

// ids

final int id_floor  = 0;
final int id_player = 1;
final int id_box    = 2;
final int id_wall   = 3;
final int id_goals  = 4;

// directions

final int dir_empty = -1;
final int dir_up    = 0;
final int dir_down  = 1;
final int dir_left  = 2;
final int dir_right = 3;

// game state

int queued_dir = dir_empty;
int player_x = 0;
int player_y = 0;
int box_x = 4;
int box_y = 4;

// game initial parameters

Grid grid = new Grid();

String initial_level = "l3.lvl";

class Grid {
  boolean solved = false;
  int w;
  int h;
  int [][] lookup;
  IVec3 player = new IVec3(0, 0, 0);
  ArrayList<IVec3> boxes = new ArrayList();
  ArrayList<IVec3> walls = new ArrayList();
  ArrayList<IVec3> goals = new ArrayList();
}

void load_default_grid() {
  grid.solved = false;
  grid.w = 10;
  grid.h = 10;
  grid.lookup = new int[grid.h][grid.w];
  grid.player = new IVec3(0, 0, 0);

  grid.boxes.add(new IVec3(4, 4, 0));
  grid.walls.add(new IVec3(4, 7, 0));
  grid.walls.add(new IVec3(4, 8, 0));
  grid.walls.add(new IVec3(5, 8, 0));
  grid.walls.add(new IVec3(6, 8, 0));
  grid.walls.add(new IVec3(7, 8, 0));
  grid.walls.add(new IVec3(8, 8, 0));

  grid.goals.add(new IVec3(3, 3, 0));

  update_grid_lookup(grid);
}

void load_grid(String file) {

  String[] lines = loadStrings(file);
  println("There are " + lines.length + " lines");

  int header_lines = 2;
  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];
    if (i == 0) {
      println("Version: " + line);
    } else if ( i == 1 ) {
      println("Size: " + line);
      String[] size = line.split(" ");
      grid = new Grid();
      grid.solved = false;
      grid.w = int(size[1]);
      grid.h = int(size[0]);
      grid.lookup = new int[grid.h][grid.w];
    } else {
      String[] elems = line.split("");
      int y = i - header_lines;
      int x = 0;

      for (String e : elems) {
        if (e.equals("W")) {
          grid.walls.add(new IVec3(x, y, 0));
        } else if (e.equals("B")) {
          grid.boxes.add(new IVec3(x, y, 0));
        } else if (e.equals("P")) {
          grid.player = new IVec3(x, y, 0);
        } else if (e.equals("G")) {
          grid.goals.add(new IVec3(x, y, 0));
        } 

        x += 1;
      }
    }
  }
  update_grid_lookup(grid);


  println("Walls: " + grid.walls.size());
  println("Boxes: " + grid.boxes.size());
  println("Goals: " + grid.goals.size());
}

void update_grid_lookup(Grid grid) {
  update_grid_lookup_player(grid);
  update_grid_lookup_boxes(grid);
  update_grid_lookup_walls(grid);
}

void update_grid_lookup_player(Grid grid) {
  grid.lookup[grid.player.y][grid.player.x] = id_player;
}

void update_grid_lookup_boxes(Grid grid) {
  for (IVec3 g : grid.boxes) {
    grid.lookup[g.y][g.x] = id_box;
  }
}

void update_grid_lookup_walls(Grid grid) {
  for (IVec3 g : grid.walls) {
    grid.lookup[g.y][g.x] = id_wall;
  }
}


void setup() {
  size(600, 600);
  background(100);
  noFill();

  load_grid(initial_level);
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    case UP:
      queued_dir = dir_up;
      break;
    case DOWN:
      queued_dir = dir_down;
      break;
    case LEFT:
      queued_dir = dir_left;
      break;
    case RIGHT:
      queued_dir = dir_right;
      break;
    default:
      queued_dir = dir_empty;
    }
    return;
  }

  if (key == 'r' || key == 'R') {
    println("reloading");
    load_grid(initial_level);
  }
}

boolean in_bounds_x(Grid grid, int x) {
  return x >= 0 && x < grid.w;
}

boolean in_bounds_y(Grid grid, int y) {
  return y >= 0 && y < grid.h;
}

boolean in_bounds(Grid grid, int x, int y) {
  if (y < 0 || y >= grid.h || x < 0 || x >= grid.w) return false;
  return true;
}

IVec3 get_increment(Grid grid, int x, int y, int direction) {
  IVec3 inc = null;
  switch(direction) {
  case dir_up:
    if (in_bounds_y(grid, y - 1)) inc = new IVec3(0, -1, 0); 
    break;
  case dir_down:
    if (in_bounds_y(grid, y + 1)) inc = new IVec3(0, 1, 0);
    break;
  case dir_left:
    if (in_bounds_x(grid, x - 1)) inc = new IVec3(-1, 0, 0);
    break;
  case dir_right:
    if (in_bounds_x(grid, x + 1)) inc = new IVec3(1, 0, 0);
    break;
  }

  return inc;
}

void add_increment_to_object(ArrayList<IVec3> objects, int x, int y, IVec3 inc) {
  for (IVec3 g : objects) {
    if (g.x == x && g.y == y) {
      g.x += inc.x;
      g.y += inc.y;
      g.z += inc.z;
    }
  }
}

void handle_input(Grid grid, int direction) {
  IVec3 player_inc = get_increment(grid, grid.player.x, grid.player.y, direction);

  if (player_inc != null) {
    int np_x = grid.player.x + player_inc.x;
    int np_y = grid.player.y + player_inc.y;

    if (grid.lookup[np_y][np_x] == id_wall) return;

    if (grid.lookup[np_y][np_x] == id_box) {
      IVec3 box_inc = get_increment(grid, grid.player.x + player_inc.x, grid.player.y + player_inc.y, direction);

      if (box_inc == null) return;

      int nb_x = np_x + box_inc.x;
      int nb_y = np_y + box_inc.y;
      if (grid.lookup[nb_y][nb_x] == id_wall) return;
      if (grid.lookup[nb_y][nb_x] == id_box) return;

      add_increment_to_object(grid.boxes, np_x, np_y, box_inc);
      update_grid_lookup_boxes(grid);
    }

    grid.player.x += player_inc.x;
    grid.player.y += player_inc.y;
    grid.player.z += player_inc.z;
    update_grid_lookup_player(grid);
  }
}

boolean is_solved(Grid grid) {
  int x = grid.player.x;
  int y = grid.player.y;

  for (IVec3 g : grid.goals) {
    if (g.x == x && g.y == y) return true;
  }
  return false;
}

void draw() {
  // background
  if (grid.solved) {
    background(100, 200, 100);
  } else {
    background(100);
  }

  // parameters that could be tweaked

  int board_offset = 40;
  int grid_cell_size = 20;
  int grid_cell_spacing = 30;

  // interaction

  handle_input(grid, queued_dir);
  queued_dir = dir_empty;

  if (is_solved(grid)) grid.solved = true;

  // rendering
  for (int ih = 0; ih < grid.h; ih++) {
    for (int iw = 0; iw < grid.w; iw++) {
      int screen_x = (iw * grid_cell_spacing) + board_offset;
      int screen_y = (ih * grid_cell_spacing) + board_offset;

      fill(10 + iw * 2, 10 + ih, 10);
      rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
    }
  }

  for (IVec3 g : grid.goals) {
    fill(200, 200, 200);
    int screen_x = (g.x * grid_cell_spacing) + board_offset;
    int screen_y = (g.y * grid_cell_spacing) + board_offset;
    rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
  }

  for (IVec3 g : grid.boxes) {
    fill(102, 10, 0);
    int screen_x = (g.x * grid_cell_spacing) + board_offset;
    int screen_y = (g.y * grid_cell_spacing) + board_offset;
    rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
  }

  for (IVec3 g : grid.walls) {
    fill(10, 10, 110);
    int screen_x = (g.x * grid_cell_spacing) + board_offset;
    int screen_y = (g.y * grid_cell_spacing) + board_offset;
    rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
  }

  fill(102, 10, 110);
  int screen_x = (grid.player.x * grid_cell_spacing) + board_offset;
  int screen_y = (grid.player.y * grid_cell_spacing) + board_offset;
  rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
}
