module jarjar_fs::jarjar_fs {
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set::{Self, VecSet};
    use std::string::{String};
    use sui::object::delete;
    use sui::clock::{Self, Clock}; // Add this import

    // Struct to represent a chunk of file data
    public struct FileChunk has store, copy, drop {
        index: u64,
        data: vector<u8>,
    }

    // Updated File struct with created_at field
    public struct File has key {
        id: UID,
        owner: address,
        chunks: VecMap<u64, FileChunk>,
        chunk_order: VecSet<u64>,
        file_size: u64,
        file_name: String,
        created_at: u64,
    }

    // Error codes
    const EInvalidChunkIndex: u8 = 0;
    const EChunkAlreadyExists: u8 = 1;

    // Updated function to create a new file object
    public fun create_file(file_size: u64, file_name: String, clock: &Clock, ctx: &mut TxContext): ID {
        let file = File {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            chunks: vec_map::empty(),
            chunk_order: vec_set::empty(),
            file_size,
            file_name,
            created_at: clock::timestamp_ms(clock),
        };
        let file_id = object::id(&file);
        transfer::transfer(file, tx_context::sender(ctx));
        file_id
    }

    // Updated function to get file info
    public fun get_file_info(file: &File): (u64, String, u64) {
        (file.file_size, file.file_name, file.created_at)
    }

    // Function to add a chunk to the file
    public fun add_chunk(file: &mut File, index: u64, data: vector<u8>, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == file.owner, 0);
        assert!(!vec_set::contains(&file.chunk_order, &index), EChunkAlreadyExists as u64);

        let chunk = FileChunk { index, data };
        vec_map::insert(&mut file.chunks, index, chunk);
        vec_set::insert(&mut file.chunk_order, index);
    }

    // Function to get a chunk from the file
    public fun get_chunk(file: &File, index: u64): FileChunk {
        assert!(vec_map::contains(&file.chunks, &index ), EInvalidChunkIndex as u64);
        *vec_map::get(&file.chunks, &index)
    }

    // Function to get the number of chunks in the file
    public fun chunk_count(file: &File): u64 {
        vec_set::size(&file.chunk_order)
    }

    // Function to get the ordered list of chunk indices
    public fun get_chunk_order(file: &File): vector<u64> {
        vec_set::into_keys(copy file.chunk_order)
    }

    // Updated function to delete the File object and its chunks
    public fun delete_file(file: File, ctx: &TxContext) {
        let File { id, owner, chunks: _, chunk_order: _, file_size: _, file_name: _, created_at: _ } = file;
        assert!(tx_context::sender(ctx) == owner, 0);
        delete(id);
    }
}